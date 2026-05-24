using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace GerenciamentoCliente.App.Shared;

/// <summary>
///     Validates Brazilian CPF using the official check-digit algorithm.
///     Accepts both masked (xxx.xxx.xxx-xx) and unmasked (xxxxxxxxxxx) formats.
/// </summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter)]
public class CpfAttribute : ValidationAttribute
{
    // Strips any non-digit character so both "123.456.789-09" and "12345678909" are accepted
    private static readonly Regex NonDigit = new(@"\D", RegexOptions.Compiled);

    public CpfAttribute() : base("CPF inválido.")
    {
    }

    public override bool IsValid(object? value)
    {
        if (value is null)
            return true;

        var raw = value.ToString()?.Trim() ?? "";

        if (string.IsNullOrEmpty(raw))
            return true;

        var digits = NonDigit.Replace(raw, "");

        return digits.Length == 11 && !AllDigitsSame(digits) && HasValidCheckDigits(digits);
    }

    // CPFs like "111.111.111-11" pass the digit formula but are explicitly invalid
    private static bool AllDigitsSame(string digits) =>
        digits.Distinct().Count() == 1;

    private static bool HasValidCheckDigits(string digits)
    {
        // First check digit: weights 10..2 applied to the first 9 digits
        var firstDigit = CalculateCheckDigit(digits, 10);
        if (firstDigit != (digits[9] - '0'))
            return false;

        // Second check digit: weights 11..2 applied to the first 10 digits
        var secondDigit = CalculateCheckDigit(digits, 11);
        return secondDigit == (digits[10] - '0');
    }

    private static int CalculateCheckDigit(string digits, int initialWeight)
    {
        var count = initialWeight - 1; // number of digits to include
        var sum = digits
            .Take(count)
            .Select((c, i) => (c - '0') * (initialWeight - i))
            .Sum();

        var remainder = (sum * 10) % 11;

        // Remainder 10 or 11 is normalised to 0 per the CPF spec
        return remainder >= 10 ? 0 : remainder;
    }
}
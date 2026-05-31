using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace GerenciamentoCliente.Application.Shared;

/// <summary>
///     Validates Brazilian phone number by digit count (10 for landline, 11 for mobile).
///     Accepts any formatting — digits are extracted before validation.
/// </summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter)]
public class TelefoneAttribute : ValidationAttribute
{
    public TelefoneAttribute() : base("O telefone deve conter 10 dígitos (fixo) ou 11 dígitos (celular).")
    {
    }

    public override bool IsValid(object? value)
    {
        if (value is null)
            return true;

        var telefone = value.ToString()?.Trim() ?? "";

        if (string.IsNullOrEmpty(telefone))
            return true;

        var digits = Regex.Replace(telefone, @"\D", "");

        return digits.Length is 10 or 11;
    }
}
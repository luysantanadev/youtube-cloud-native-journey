using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace GerenciamentoCliente.Adm.Validations;

/// <summary>
///     Validates Brazilian phone format
///     Accepts: xx x xxxx-xxxx (mobile) or xx xxxx-xxxx (landline)
/// </summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter)]
public class TelefoneAttribute : ValidationAttribute
{
    private const string PhonePattern = @"^(\d{2}\s\d{4}-\d{4}|\d{2}\s\d{5}-\d{4}|\d{2}\d{4}-\d{4})$";

    public TelefoneAttribute() : base(
        "O telefone deve estar no formato (11) 9xxxx-xxxx para celular ou (11) xxxx-xxxx para fixo")
    {
    }

    public override bool IsValid(object? value)
    {
        if (value is null)
            return true;

        var telefone = value.ToString()?.Trim() ?? "";

        if (string.IsNullOrEmpty(telefone))
            return true;

        return Regex.IsMatch(telefone, PhonePattern);
    }
}
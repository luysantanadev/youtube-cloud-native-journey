using System.ComponentModel.DataAnnotations;
using System.Text.RegularExpressions;

namespace GerenciamentoCliente.Adm.Validations;

/// <summary>
///     Validates Brazilian CPF format (xxx.xxx.xxx-xx)
/// </summary>
[AttributeUsage(AttributeTargets.Property | AttributeTargets.Field | AttributeTargets.Parameter)]
public class CpfAttribute : ValidationAttribute
{
    private const string CpfPattern = @"^\d{3}\.\d{3}\.\d{3}-\d{2}$";

    public CpfAttribute() : base("O CPF deve estar no formato xxx.xxx.xxx-xx")
    {
    }

    public override bool IsValid(object? value)
    {
        if (value is null)
            return true;

        var cpf = value.ToString()?.Trim() ?? "";

        if (string.IsNullOrEmpty(cpf))
            return true;

        return Regex.IsMatch(cpf, CpfPattern);
    }
}
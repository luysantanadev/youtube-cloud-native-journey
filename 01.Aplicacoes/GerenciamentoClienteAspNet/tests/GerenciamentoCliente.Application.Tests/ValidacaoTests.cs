using System.ComponentModel.DataAnnotations;
using GerenciamentoCliente.App.Clientes;
using GerenciamentoCliente.App.Shared;

namespace GerenciamentoCliente.Application.Tests;

// Simple validation test for CPF and Telefone attributes
public class ValidacaoTests
{
    private readonly CpfAttribute _cpfValidator = new();
    private readonly TelefoneAttribute _telefoneValidator = new();

    // Test examples for CPF format: xxx.xxx.xxx-xx
    public void TestarCpfFormatos()
    {
        Console.WriteLine("=== Testando CPF ===");

        // Valid CPF formats
        var cpfValido1 = "123.456.789-09";
        var cpfValido2 = "111.222.333-44";

        Console.WriteLine($"CPF '{cpfValido1}' válido: {_cpfValidator.IsValid(cpfValido1)}");
        Console.WriteLine($"CPF '{cpfValido2}' válido: {_cpfValidator.IsValid(cpfValido2)}");

        // Invalid CPF formats
        var cpfInvalido1 = "12345678909"; // sem máscara
        var cpfInvalido2 = "123.456.78909"; // formato errado
        var cpfInvalido3 = "123-456-789.09"; // formato errado

        Console.WriteLine($"CPF '{cpfInvalido1}' válido: {_cpfValidator.IsValid(cpfInvalido1)}");
        Console.WriteLine($"CPF '{cpfInvalido2}' válido: {_cpfValidator.IsValid(cpfInvalido2)}");
        Console.WriteLine($"CPF '{cpfInvalido3}' válido: {_cpfValidator.IsValid(cpfInvalido3)}");
    }

    // Test examples for Telefone formats
    // Celular: xx x xxxx-xxxx (with space) or xx xxxxx-xxxx
    // Fixo: xx xxxx-xxxx
    public void TestarTelefoneFormatos()
    {
        Console.WriteLine("\n=== Testando Telefone ===");

        // Valid formats
        var celularComEspaco = "11 9 9999-8888"; // celular com espaço
        var celularSemEspaco = "11 99999-8888"; // celular sem espaço meio
        var fixo = "11 3333-4444"; // fixo

        Console.WriteLine($"Celular '{celularComEspaco}' válido: {_telefoneValidator.IsValid(celularComEspaco)}");
        Console.WriteLine($"Celular '{celularSemEspaco}' válido: {_telefoneValidator.IsValid(celularSemEspaco)}");
        Console.WriteLine($"Fixo '{fixo}' válido: {_telefoneValidator.IsValid(fixo)}");

        // Invalid formats
        var invalido1 = "11999998888"; // sem máscara
        var invalido2 = "(11) 99999-8888"; // com parênteses
        var invalido3 = "11 9999-888"; // número incompleto

        Console.WriteLine($"Telefone '{invalido1}' válido: {_telefoneValidator.IsValid(invalido1)}");
        Console.WriteLine($"Telefone '{invalido2}' válido: {_telefoneValidator.IsValid(invalido2)}");
        Console.WriteLine($"Telefone '{invalido3}' válido: {_telefoneValidator.IsValid(invalido3)}");
    }

    public void TestarViewModelValidacao()
    {
        Console.WriteLine("\n=== Testando ClienteCadastroViewModel ===");

        var viewModel = new ClienteCadastroViewModel
        {
            NomeCompleto = "João Silva",
            Cpf = "123.456.789-09",
            Nascimento = new DateOnly(1990, 1, 15),
            Email = "joao.silva@example.com",
            Telefone = "11 9 9999-8888"
        };

        var context = new ValidationContext(viewModel, null, null);
        var results = new List<ValidationResult>();
        var isValid = Validator.TryValidateObject(viewModel, context, results, true);

        Console.WriteLine($"ViewModel válido: {isValid}");
        if (!isValid)
            foreach (var error in results)
                Console.WriteLine($"  - {error.ErrorMessage}");
    }
}
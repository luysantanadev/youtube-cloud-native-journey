using System.Text.RegularExpressions;
using Flunt.Br;
using Flunt.Extensions.Br.Validations;
using Flunt.Notifications;

namespace GerenciamentoCliente.Domain.Clientes;

public class Cliente : Notifiable<Notification>
{
    // // Construtor EF Core

    public Cliente(int id, string nomeCompleto, string cpf)
    {
        Id = id;
        NomeCompleto = nomeCompleto;
        Cpf = cpf;
    }

    protected Cliente(int id, string nomeCompleto, string cpf, DateOnly nascimento, string email, string telefone)
    {
        Id = id;
        AtualizarNome(nomeCompleto);
        AtualizarCpf(cpf);
        AtualizarNascimento(nascimento);
        AtualizarEmail(email);
        AtualizarTelefone(telefone);
    }

    public Cliente(string nomeCompleto, string cpf, DateOnly nascimento, string email, string telefone)
    {
        AtualizarNome(nomeCompleto);
        AtualizarCpf(cpf);
        AtualizarNascimento(nascimento);
        AtualizarEmail(email);
        AtualizarTelefone(telefone);
    }

    public Cliente()
    {
    }

    private List<Endereco> _enderecos { get; } = new();

    public int Id { get; private set; }
    public string NomeCompleto { get; private set; }
    public string Cpf { get; private set; }
    public DateOnly Nascimento { get; private set; }
    public string Email { get; private set; }
    public string Telefone { get; private set; }

    public IReadOnlyList<Endereco> Enderecos => _enderecos.AsReadOnly();

    public void AdicionarEndereco(Endereco endereco)
    {
        AddNotifications(endereco);
        _enderecos.Add(endereco);
    }

    public void AtualizarNome(string? nomeCompleto)
    {
        var nome = nomeCompleto?.Trim().ToUpper() ?? "";
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(nome, "NomeCompleto", "O nome completo é obrigatório")
            .IsGreaterOrEqualsThan(nome, 3, "NomeCompleto", "O nome completo deve conter mais de 3 caracteres")
            .IsLowerOrEqualsThan(nome, 100, "NomeCompleto", "O nome completo deve conter menos de 100 caracteres"));
        NomeCompleto = nome;
    }

    public void AtualizarCpf(string? cpf)
    {
        var cpfNormalizado = Regex.Replace(cpf ?? "", @"[^\d]", "");
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(cpfNormalizado, "Cpf", "O CPF é obrigatório")
            .IsCpf(cpfNormalizado, "Cpf", "O CPF é inválido"));
        Cpf = cpfNormalizado;
    }

    public void AtualizarNascimento(DateOnly? nascimento)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsNotNull(nascimento, "Nascimento", "A data de nascimento é obrigatória")
            .IsGreaterOrEqualsThan(
                nascimento.GetValueOrDefault().ToDateTime(new TimeOnly()),
                DateTime.Now.AddYears(-120),
                "Nascimento",
                "A data de nascimento deve ser maior ou igual a 150 anos atrás")
            .IsLowerThan(
                nascimento.GetValueOrDefault().ToDateTime(new TimeOnly()),
                DateTime.Now.AddDays(-18),
                "Nascimento",
                "O Cliente deve ser maior de idade"));
        Nascimento = nascimento.GetValueOrDefault();
    }

    public void AtualizarEmail(string? email)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(email, "Email", "O email é obrigatório")
            .IsLowerOrEqualsThan(email, 75, "Email", "O email deve conter no máximo 75 caracteres")
            .IsEmail(email, "Email", "O email é inválido"));
        Email = email?.Trim().ToLower() ?? "";
    }

    public void AtualizarTelefone(string? telefone)
    {
        var telefoneNormalizado = Regex.Replace(telefone ?? "", @"[^\d]", "");
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(telefoneNormalizado, "Telefone", "O telefone é obrigatório")
            .IsGreaterOrEqualsThan(telefoneNormalizado, 10, "Telefone", "O telefone deve conter ao menos 10 caracteres")
            .IsLowerOrEqualsThan(telefoneNormalizado, 11, "Telefone",
                "O telefone deve conter no máximo 11 caracteres"));
        Telefone = telefoneNormalizado;
    }
}
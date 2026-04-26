using System.Text.RegularExpressions;
using Flunt.Br;
using Flunt.Extensions.Br.Validations;
using Flunt.Notifications;

namespace GerenciamentoCliente.Adm.Models;

public class Cliente : Notifiable<Notification>
{
    // // Construtor EF Core
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

    public int Id { get; private set; }
    public string NomeCompleto { get; private set; }
    public string Cpf { get; private set; }
    public DateOnly Nascimento { get; private set; }
    public string Email { get; private set; }
    public string Telefone { get; private set; }

    public void AtualizarNome(string? nomeCompleto)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(nomeCompleto, "NomeCompleto", "O nome completo é obrigatório")
            .IsGreaterThan(nomeCompleto, 3, "NomeCompleto", "O nome completo deve conter mais de 3 caracteres")
            .IsLowerThan(nomeCompleto, 100, "NomeCompleto", "O nome completo deve conter menos de 100 caracteres"));
        NomeCompleto = nomeCompleto?.Trim().ToUpper() ?? "";
    }

    public void AtualizarCpf(string? cpf)
    {
        var cpfNormalizado = Regex.Replace(cpf ?? "", @"[^\D]", "");
        AddNotifications(new Contract()
            .Requires()
            .IsNullOrWhiteSpace(cpfNormalizado, "Cpf", "O CPF é obrigatório")
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
            .IsEmail(email, "Email", "O email é inválido"));
        Email = email?.Trim().ToLower() ?? "";
    }

    public void AtualizarTelefone(string? telefone)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(telefone, "Telefone", "O telefone é obrigatório")
            .IsGreaterThan(telefone, 10, "Telefone", "O telefone deve conter mais de 10 caracteres")
            .IsLowerOrEqualsThan(telefone, 11, "Telefone", "O telefone deve conter no máximo 11 caracteres"));
        Telefone = Regex.Replace(telefone ?? "", @"[^\D]", "");
    }
}

public class Endereco : Notifiable<Notification>
{
    // Constructor for EF Core
    protected Endereco(int id, string logradouro, string numero, string complemento, string referencia, string bairro,
        string cep, int cidadeId, Cidade cidade)
    {
        Id = id;
        Cidade = cidade;
        AtualizarLogradouro(logradouro);
        AtualizarNumero(numero);
        AtualizarComplemento(complemento);
        AtualizarReferencia(referencia);
        AtualizarBairro(bairro);
        AtualizarCep(cep);
        AtualizarCidade(cidadeId);
    }

    public Endereco(string logradouro, string numero, string complemento, string referencia, string bairro, string cep,
        int cidadeId)
    {
        AtualizarLogradouro(logradouro);
        AtualizarNumero(numero);
        AtualizarComplemento(complemento);
        AtualizarReferencia(referencia);
        AtualizarBairro(bairro);
        AtualizarCep(cep);
        AtualizarCidade(cidadeId);
    }

    public int Id { get; private set; }
    public string Logradouro { get; private set; }
    public string Numero { get; private set; }
    public string Complemento { get; private set; }
    public string Referencia { get; private set; }
    public string Bairro { get; private set; }
    public string Cep { get; private set; }
    public int CidadeId { get; private set; }
    public Cidade Cidade { get; private set; }

    public void AtualizarLogradouro(string? logradouro)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(logradouro, "Logradouro", "O logradouro é obrigatório")
            .IsGreaterThan(logradouro, 3, "Logradouro", "O logradouro deve conter mais de 3 caracteres")
            .IsLowerThan(logradouro, 150, "Logradouro", "O logradouro deve conter menos de 150 caracteres"));
        Logradouro = logradouro?.Trim().ToUpper() ?? "";
    }

    public void AtualizarNumero(string? numero)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(numero, "Numero", "O número é obrigatório")
            .IsGreaterOrEqualsThan(numero, 1, "Numero", "O número deve conter pelo menos 1 caractere")
            .IsLowerOrEqualsThan(numero, 10, "Numero", "O número deve conter no máximo 10 caracteres"));
        Numero = numero?.Trim().ToUpper() ?? "";
    }

    public void AtualizarComplemento(string? complemento)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsGreaterOrEqualsThan(complemento, 3, "Complemento", "O complemento deve conter pelo menos 3 caracteres")
            .IsLowerOrEqualsThan(complemento, 100, "Complemento",
                "O complemento deve conter no máximo 100 caracteres"));
        Complemento = complemento?.Trim().ToUpper() ?? "";
    }

    public void AtualizarReferencia(string? referencia)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsGreaterOrEqualsThan(referencia, 3, "Referencia", "A referência deve conter pelo menos 3 caracteres")
            .IsLowerOrEqualsThan(referencia, 150, "Referencia", "A referência deve conter no máximo 150 caracteres"));
        Referencia = referencia?.Trim().ToUpper() ?? "";
    }

    public void AtualizarBairro(string? bairro)
    {
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(bairro, "Bairro", "O bairro é obrigatório")
            .IsGreaterThan(bairro, 2, "Bairro", "O bairro deve conter mais de 2 caracteres")
            .IsLowerThan(bairro, 100, "Bairro", "O bairro deve conter menos de 100 caracteres"));
        Bairro = bairro?.Trim().ToUpper() ?? "";
    }

    public void AtualizarCep(string? cep)
    {
        var cepNormalizado = Regex.Replace(cep ?? "", @"\D", "");

        // CEP must have exactly 8 digits after stripping non-numeric characters
        AddNotifications(new Contract()
            .Requires()
            .IsNotNullOrWhiteSpace(cep, "Cep", "O CEP é obrigatório")
            .IsTrue(cepNormalizado.Length == 8, "Cep", "O CEP deve conter 8 dígitos"));
        Cep = cepNormalizado;
    }

    public void AtualizarCidade(int cidadeId)
    {
        // CidadeId must reference a valid city (positive value)
        AddNotifications(new Contract()
            .Requires()
            .IsGreaterThan(cidadeId, 0, "CidadeId", "A cidade é obrigatória"));
        CidadeId = cidadeId;
    }
}

public class Cidade
{
    public Cidade(int id, int estadoId, string nome)
    {
        Id = id;
        EstadoId = estadoId;
        Nome = nome;
    }

    public int Id { get; private set; }
    public int EstadoId { get; private set; }
    public string Nome { get; private set; }
    
    public Estado  Estado { get; private set; }
}

public class Estado
{
    private List<Cidade> _cidades { get; set; }= new List<Cidade>();
    
    public Estado(int id, string sigla, string nome)
    {
        Id = id;
        Sigla = sigla;
        Nome = nome;
    }

    public int Id { get; private set; }
    public string Sigla { get; private set; }
    public string Nome { get; private set; }
    
    public IReadOnlyList<Cidade> Cidades => _cidades.AsReadOnly();
}
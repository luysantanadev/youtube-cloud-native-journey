namespace GerenciamentoCliente.Application.Clientes;

public class EnderecoDetalhesViewModel
{
    public int Id { get; set; }
    public string Logradouro { get; set; }
    public string Numero { get; set; }
    public string Complemento { get; set; }
    public string Referencia { get; set; }
    public string Bairro { get; set; }
    public string Cep { get; set; }
    public int CidadeId { get; set; }
    public string CidadeNome { get; set; }
    public string EstadoSigla { get; set; }
}
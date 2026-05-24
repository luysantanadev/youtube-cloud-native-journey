namespace GerenciamentoCliente.App.Clientes;

public class ClientePaginacaoViewModel
{
    public IReadOnlyList<ClienteIndexViewModel> Itens { get; set; } = new List<ClienteIndexViewModel>();
    public string? Consulta { get; set; } = string.Empty;
    public int Pagina { get; set; }
    public int TamanhoPagina { get; set; }
    public int TotalItems { get; set; }
    public int TotalPages { get; set; }
}
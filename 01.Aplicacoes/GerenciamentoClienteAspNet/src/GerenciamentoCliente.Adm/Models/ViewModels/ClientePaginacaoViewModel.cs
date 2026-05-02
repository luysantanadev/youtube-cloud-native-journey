namespace GerenciamentoCliente.Adm.Models.ViewModels;

public class ClientePaginacaoViewModel
{
    public IReadOnlyList<ClienteIndexViewModel> Itens { get; set; } = new List<ClienteIndexViewModel>();
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalItems { get; set; }
    public int TotalPages { get; set; }
}
using System.ComponentModel.DataAnnotations;

namespace GerenciamentoCliente.App.Clientes;

public class ClienteDetalhesViewModel : ClienteAtualizarViewModel
{
    [Display(Name = "Endereços")]
    public IReadOnlyList<EnderecoDetalhesViewModel> Enderecos { get; set; } = new List<EnderecoDetalhesViewModel>();
}
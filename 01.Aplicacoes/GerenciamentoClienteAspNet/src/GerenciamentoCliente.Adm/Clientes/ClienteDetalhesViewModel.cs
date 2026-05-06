using System.ComponentModel.DataAnnotations;

namespace GerenciamentoCliente.Adm.Clientes;

public class ClienteDetalhesViewModel : ClienteAtualizarViewModel
{
    [Display(Name = "Endereços")]
    public IReadOnlyList<EnderecoDetalhesViewModel> Enderecos { get; set; } = new List<EnderecoDetalhesViewModel>();
}
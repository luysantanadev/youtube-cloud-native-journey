using GerenciamentoCliente.Application.Clientes;
using Microsoft.AspNetCore.Mvc;

namespace GerenciamentoCliente.Adm.Controllers;

public class ClientesController : Controller
{
    private readonly IClienteServico _servico;

    public ClientesController(IClienteServico servico) =>
        _servico = servico;


    // GET: Clientes
    public async Task<IActionResult> Index(
        ClientePaginacaoParametros parametros,
        CancellationToken token)
    {
        var consulta = await _servico.Buscar(parametros, token);
        return View(consulta);
    }

    // GET: Clientes/Details/5
    public async Task<IActionResult> Details(int? id, CancellationToken token)
    {
        if (id == null) return NotFound();
        var cliente = await _servico.Buscar(id.Value, token);
        if (cliente == null) return NotFound();
        return View(cliente);
    }

    // GET: Clientes/Create
    public IActionResult Create()
    {
        return View();
    }

    // POST: Clientes/Create
    // To protect from overposting attacks, enable the specific properties you want to bind to.
    // For more details, see http://go.microsoft.com/fwlink/?LinkId=317598.
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(
        [Bind("NomeCompleto,Cpf,Nascimento,Email,Telefone")]
        ClienteCadastroViewModel cliente, CancellationToken token)
    {
        if (!ModelState.IsValid)
            return View(cliente);

        var notificacoes = await _servico.Cadastrar(cliente, token);

        if (!notificacoes.Any())
            return RedirectToAction(nameof(Index));

        foreach (var validacao in notificacoes)
            ModelState.AddModelError(validacao.Key, validacao.Message);

        return View(cliente);
    }

    // GET: Clientes/Edit/5
    public async Task<IActionResult> Edit(int? id, CancellationToken token)
    {
        if (id == null) return NotFound();
        var cliente = await _servico.Buscar(id.Value, token);
        if (cliente == null) return NotFound();
        return View(cliente);
    }

    // POST: Clientes/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id,
        [Bind("Id,NomeCompleto,Cpf,Nascimento,Email,Telefone")]
        ClienteAtualizarViewModel cliente, CancellationToken token)
    {
        if (id != cliente.Id) return NotFound();

        if (!ModelState.IsValid)
            return View(cliente);

        var notificacoes = await _servico.Atualizar(cliente, token);

        if (!notificacoes.Any())
            return RedirectToAction(nameof(Index));

        foreach (var validacao in notificacoes)
            ModelState.AddModelError(validacao.Key, validacao.Message);

        return View(cliente);
    }


    // GET: Clientes/Delete/5
    public async Task<IActionResult> Delete(int? id, CancellationToken token)
    {
        if (id == null) return NotFound();
        var cliente = await _servico.Buscar(id.Value, token);
        if (cliente == null) return NotFound();
        return View(cliente);
    }

    // POST: Clientes/Delete/5
    [HttpPost]
    [ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(int id, CancellationToken token)
    {
        await _servico.Excluir(id, token);
        return RedirectToAction(nameof(Index));
    }
}
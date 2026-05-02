using GerenciamentoCliente.Adm.Models;
using GerenciamentoCliente.Adm.Models.ViewModels;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GerenciamentoCliente.Adm.Controllers;

public class ClientesController : Controller
{
    private readonly GerenciamentoClienteContexto _context;

    public ClientesController(GerenciamentoClienteContexto context)
    {
        _context = context;
    }

    // GET: Clientes
    public async Task<IActionResult> Index(int page = 1, int pageSize = 10)
    {
        if (page <= 0)
            page = 1;

        if (pageSize <= 0)
            pageSize = 10;
        else if (pageSize > 100)
            pageSize = 100;

        var query = _context
            .Clientes
            .OrderBy(x => x.NomeCompleto);

        var totalItems = await query.CountAsync();
        var totalPages = (int)Math.Ceiling(totalItems / (double)pageSize);

        var itens = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => new ClienteIndexViewModel
            {
                Id = x.Id,
                NomeCompleto = x.NomeCompleto,
                Cpf = x.Cpf,
                Nascimento = x.Nascimento,
                Email = x.Email,
                Telefone = x.Telefone
            })
            .ToListAsync();

        var viewModel = new ClientePaginacaoViewModel
        {
            Itens = itens,
            Page = page,
            PageSize = pageSize,
            TotalItems = totalItems,
            TotalPages = totalPages
        };

        return View(viewModel);
    }

    // GET: Clientes/Details/5
    public async Task<IActionResult> Details(int? id)
    {
        if (id == null) return NotFound();

        var cliente = await _context
            .Clientes
            .Include(x => x.Enderecos)
            .ThenInclude(x => x.Cidade)
            .ThenInclude(x => x.Estado)
            .Where(x => x.Id == id)
            .FirstOrDefaultAsync();

        if (cliente == null) return NotFound();

        var enderecos = cliente
            .Enderecos
            .Select(e => new EnderecoDetalhesViewModel
            {
                Id = e.Id,
                Logradouro = e.Logradouro,
                Numero = e.Numero,
                Complemento = e.Complemento,
                Referencia = e.Referencia,
                Bairro = e.Bairro,
                Cep = e.Cep,
                CidadeId = e.CidadeId,
                CidadeNome = e.Cidade?.Nome ?? "",
                EstadoSigla = e.Cidade?.Estado?.Sigla ?? ""
            }).ToList();

        var viewModel = new ClienteDetalhesViewModel
        {
            Id = cliente.Id,
            NomeCompleto = cliente.NomeCompleto,
            Cpf = cliente.Cpf,
            Nascimento = cliente.Nascimento,
            Email = cliente.Email,
            Telefone = cliente.Telefone,
            Enderecos = enderecos
        };

        return View(viewModel);
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
        ClienteCadastroViewModel cliente)
    {
        if (!ModelState.IsValid)
            return View(cliente);
        var novoCliente = new Cliente(cliente.NomeCompleto, cliente.Cpf, cliente.Nascimento, cliente.Email,
            cliente.Telefone);
        if (novoCliente.IsValid)
        {
            _context.Add(novoCliente);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        foreach (var validacao in novoCliente.Notifications)
            ModelState.AddModelError(validacao.Key, validacao.Message);

        return View(cliente);
    }

    // GET: Clientes/Edit/5
    public async Task<IActionResult> Edit(int? id)
    {
        if (id == null) return NotFound();

        var cliente = await _context.Clientes.FindAsync(id);
        if (cliente == null) return NotFound();

        var viewModel = new ClienteAtualizarViewModel
        {
            Id = cliente.Id,
            NomeCompleto = cliente.NomeCompleto,
            Cpf = cliente.Cpf,
            Nascimento = cliente.Nascimento,
            Email = cliente.Email,
            Telefone = cliente.Telefone
        };

        return View(viewModel);
    }

    // POST: Clientes/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id,
        [Bind("Id,NomeCompleto,Cpf,Nascimento,Email,Telefone")]
        ClienteAtualizarViewModel clienteViewModel)
    {
        if (id != clienteViewModel.Id) return NotFound();

        if (!ModelState.IsValid)
            return View(clienteViewModel);

        var cliente = await _context.Clientes.FindAsync(id);
        if (cliente == null) return NotFound();

        cliente.AtualizarNome(clienteViewModel.NomeCompleto);
        cliente.AtualizarCpf(clienteViewModel.Cpf);
        cliente.AtualizarNascimento(clienteViewModel.Nascimento);
        cliente.AtualizarEmail(clienteViewModel.Email);
        cliente.AtualizarTelefone(clienteViewModel.Telefone);

        if (!cliente.IsValid)
        {
            foreach (var validacao in cliente.Notifications)
                ModelState.AddModelError(validacao.Key, validacao.Message);

            return View(clienteViewModel);
        }

        try
        {
            _context.Update(cliente);
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ClienteExists(clienteViewModel.Id)) return NotFound();
            throw;
        }

        return RedirectToAction(nameof(Index));
    }


    // GET: Clientes/Delete/5
    public async Task<IActionResult> Delete(int? id)
    {
        if (id == null) return NotFound();

        var cliente = await _context.Clientes.FindAsync(id);
        if (cliente == null) return NotFound();

        var viewModel = new ClienteExcluirViewModel
        {
            Id = cliente.Id,
            NomeCompleto = cliente.NomeCompleto,
            Cpf = cliente.Cpf,
            Email = cliente.Email
        };

        return View(viewModel);
    }

    // POST: Clientes/Delete/5
    [HttpPost]
    [ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var cliente = await _context.Clientes.FindAsync(id);
        if (cliente == null) return NotFound();
        _context.Clientes.Remove(cliente);
        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(Index));
    }

    private bool ClienteExists(int id)
    {
        return _context.Clientes.Any(e => e.Id == id);
    }
}
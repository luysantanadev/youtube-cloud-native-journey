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
    public async Task<IActionResult> Index()
    {
        return View(await _context.Clientes.ToListAsync());
    }

    // GET: Clientes/Details/5
    public async Task<IActionResult> Details(int? id)
    {
        if (id == null) return NotFound();

        var cliente = await _context.Clientes
            .FirstOrDefaultAsync(m => m.Id == id);
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

        return View(cliente);
    }

    // POST: Clientes/Edit/5
    // To protect from overposting attacks, enable the specific properties you want to bind to.
    // For more details, see http://go.microsoft.com/fwlink/?LinkId=317598.
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id,
        [Bind("Id,NomeCompleto,Cpf,Nascimento,Email,Telefone")]
        Cliente cliente)
    {
        if (id != cliente.Id) return NotFound();

        if (ModelState.IsValid)
        {
            try
            {
                _context.Update(cliente);
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ClienteExists(cliente.Id)) return NotFound();

                throw;
            }

            return RedirectToAction(nameof(Index));
        }

        return View(cliente);
    }

    // GET: Clientes/Delete/5
    public async Task<IActionResult> Delete(int? id)
    {
        if (id == null) return NotFound();

        var cliente = await _context.Clientes
            .FirstOrDefaultAsync(m => m.Id == id);
        if (cliente == null) return NotFound();

        return View(cliente);
    }

    // POST: Clientes/Delete/5
    [HttpPost]
    [ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id)
    {
        var cliente = await _context.Clientes.FindAsync(id);
        if (cliente != null) _context.Clientes.Remove(cliente);

        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(Index));
    }

    private bool ClienteExists(int id)
    {
        return _context.Clientes.Any(e => e.Id == id);
    }
}
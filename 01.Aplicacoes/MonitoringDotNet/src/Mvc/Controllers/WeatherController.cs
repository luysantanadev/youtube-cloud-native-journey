using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Mvc.Data;
using Mvc.Data.Entities;
using StackExchange.Redis;
using System.Text.Json;

namespace Mvc.Controllers;

public sealed class WeatherController(AppDbContext db, IDatabase cache) : Controller
{
    private const string CacheKey = "weather:all";
    private static readonly TimeSpan CacheTtl = TimeSpan.FromSeconds(60);

    // GET /Weather
    public async Task<IActionResult> Index(CancellationToken ct)
    {
        var cached = await cache.StringGetAsync(CacheKey);
        if (cached.HasValue)
        {
            var records = JsonSerializer.Deserialize<List<WeatherRecord>>((string)cached!);
            return View(records);
        }

        var list = await db.WeatherRecords
            .OrderByDescending(r => r.RecordedAt)
            .AsNoTracking()
            .ToListAsync(ct);

        await cache.StringSetAsync(
            CacheKey,
            JsonSerializer.Serialize(list),
            CacheTtl);

        return View(list);
    }

    // GET /Weather/Details/5
    public async Task<IActionResult> Details(int id, CancellationToken ct)
    {
        var record = await db.WeatherRecords.FindAsync([id], ct);
        return record is null ? NotFound() : View(record);
    }

    // GET /Weather/Create
    public IActionResult Create() => View(new WeatherRecord { RecordedAt = DateOnly.FromDateTime(DateTime.Today) });

    // POST /Weather/Create
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(WeatherRecord record, CancellationToken ct)
    {
        if (!ModelState.IsValid)
            return View(record);

        db.WeatherRecords.Add(record);
        await db.SaveChangesAsync(ct);
        await cache.KeyDeleteAsync(CacheKey);

        return RedirectToAction(nameof(Index));
    }

    // GET /Weather/Edit/5
    public async Task<IActionResult> Edit(int id, CancellationToken ct)
    {
        var record = await db.WeatherRecords.FindAsync([id], ct);
        return record is null ? NotFound() : View(record);
    }

    // POST /Weather/Edit/5
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(int id, WeatherRecord record, CancellationToken ct)
    {
        if (id != record.Id)
            return BadRequest();

        if (!ModelState.IsValid)
            return View(record);

        db.WeatherRecords.Update(record);
        await db.SaveChangesAsync(ct);
        await cache.KeyDeleteAsync(CacheKey);

        return RedirectToAction(nameof(Index));
    }

    // GET /Weather/Delete/5
    public async Task<IActionResult> Delete(int id, CancellationToken ct)
    {
        var record = await db.WeatherRecords.FindAsync([id], ct);
        return record is null ? NotFound() : View(record);
    }

    // POST /Weather/Delete/5
    [HttpPost, ActionName("Delete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteConfirmed(int id, CancellationToken ct)
    {
        var record = await db.WeatherRecords.FindAsync([id], ct);
        if (record is not null)
        {
            db.WeatherRecords.Remove(record);
            await db.SaveChangesAsync(ct);
            await cache.KeyDeleteAsync(CacheKey);
        }

        return RedirectToAction(nameof(Index));
    }
}

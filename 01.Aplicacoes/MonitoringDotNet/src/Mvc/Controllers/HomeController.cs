using Microsoft.AspNetCore.Mvc;

namespace Mvc.Controllers;

public sealed class HomeController : Controller
{
    public IActionResult Index() => View();
}

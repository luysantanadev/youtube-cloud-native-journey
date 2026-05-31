# Design: integrar-adminlte-cdn-aspnet-mvc

Visão geral
-----------
Usar AdminLTE v4 via CDN para compor o layout principal da aplicação. O layout será dividido em partials reutilizáveis:
- Views/Shared/_Layout.cshtml  → wrapper, includes de CDN e estrutura geral
- Views/Shared/_Navbar.cshtml  → barra superior
- Views/Shared/_Sidebar.cshtml → menu lateral esquerdo (contém link Clientes)
- Views/Shared/_Footer.cshtml  → rodapé

Estrutura de pastas sugerida
---------------------------
- Views/
  - Shared/
    - _Layout.cshtml
    - _Navbar.cshtml
    - _Sidebar.cshtml
    - _Footer.cshtml
  - Clientes/
    - Index.cshtml
- Views/_ViewStart.cshtml

CDN recomendadas (exemplos)
---------------------------
Inclusão no <head> (CSS):
- Bootstrap 5 (CDN)
- Font Awesome (icons)
- AdminLTE v4 CSS (jsDelivr)

Inclusão no final do <body> (JS):
- jQuery (compatibilidade com plugins, opcional dependendo da versão do AdminLTE)
- Bootstrap bundle (Popper incluído)
- AdminLTE script (jsDelivr)

Exemplo mínimo de _Layout.cshtml
--------------------------------
@* ~/Views/Shared/_Layout.cshtml *@
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>@ViewData["Title"] - GerenciamentoCliente</title>

    <!-- CSS: Bootstrap, FontAwesome, AdminLTE -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css" crossorigin="anonymous" />
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" crossorigin="anonymous" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/admin-lte@4.0.0/dist/css/adminlte.min.css" crossorigin="anonymous" />

    @RenderSection("Styles", required: false)
</head>
<body class="hold-transition sidebar-mini layout-fixed">
    <div class="wrapper">
        <!-- Navbar -->
        @Html.Partial("_Navbar")

        <!-- Main Sidebar Container -->
        @Html.Partial("_Sidebar")

        <!-- Content Wrapper. Contains page content -->
        <div class="content-wrapper">
            <section class="content-header">
                <div class="container-fluid">
                    @RenderSection("PageHeader", required: false)
                </div>
            </section>

            <section class="content">
                <div class="container-fluid">
                    @RenderBody()
                </div>
            </section>
        </div>

        <!-- Footer -->
        @Html.Partial("_Footer")
    </div>

    <!-- JS: jQuery, Bootstrap, AdminLTE -->
    <script src="https://code.jquery.com/jquery-3.6.0.min.js" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/admin-lte@4.0.0/dist/js/adminlte.min.js" crossorigin="anonymous"></script>

    @RenderSection("Scripts", required: false)
</body>
</html>

Sidebar partial (exemplo)
-------------------------
@* ~/Views/Shared/_Sidebar.cshtml *@
<aside class="main-sidebar sidebar-dark-primary elevation-4">
    <!-- Brand Logo -->
    <a href="@Url.Action("Index","Home")" class="brand-link">
        <span class="brand-text font-weight-light">GerenciamentoCliente</span>
    </a>

    <div class="sidebar">
        <nav class="mt-2">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu">
                <li class="nav-item">
                    <a href="@Url.Action("Index", "Clientes")" class="nav-link">
                        <i class="nav-icon fas fa-users"></i>
                        <p>Clientes</p>
                    </a>
                </li>
                <!-- adicionar mais itens conforme necessário -->
            </ul>
        </nav>
    </div>
</aside>

Observações de integração
-------------------------
- Usar @Url.Action("Index","Clientes") garante que a rota aponte para a action Index do ClientesController.
- Se o projeto usar áreas (Areas), ajustar @Url.Action com new { area = "<AreaName>" }.
- _ViewStart.cshtml deve definir Layout = "~/Views/Shared/_Layout.cshtml" para aplicar globalmente.


# Proposta: integrar-adminlte-cdn-aspnet-mvc

Resumo
------
Integrar o template AdminLTE v4 via CDN no projeto ASP.NET MVC GerenciamentoClienteAspNet. Implementar um _Layout compartilhado com menu lateral esquerdo e partial views reutilizáveis, e adicionar um link no menu para a action Index do ClientesController (src/GerenciamentoCliente.Adm/Controllers/ClientesController.cs).

Motivação
---------
- Fornecer uma base de interface consistente e responsiva para a aplicação.
- Acelerar desenvolvimento usando o template AdminLTE via CDN (sem empacotar assets locais).

Escopo
------
- Incluir referências CDN (CSS e JS) necessárias no layout principal.
- Criar Views/Shared/_Layout.cshtml que segue a estrutura do AdminLTE (wrapper, sidebar, content-wrapper).
- Criar partials: Views/Shared/_Sidebar.cshtml, Views/Shared/_Navbar.cshtml, Views/Shared/_Footer.cshtml.
- Criar uma view inicial: Views/Clientes/Index.cshtml (placeholder com estrutura AdminLTE).
- Atualizar Views/_ViewStart.cshtml para apontar para o novo layout.
- Adicionar entrada "Clientes" no menu lateral apontando para @Url.Action("Index", "Clientes").

Fora do Escopo
--------------
- Customizações avançadas de tema (cores, skin) além do layout básico.
- Conversão de assets locais (não haverá inclusão de arquivos estáticos no repo — uso via CDN).

Critérios de Aceitação
----------------------
1. O layout é aplicado globalmente (Views/_ViewStart.cshtml aponta para ~/Views/Shared/_Layout.cshtml).
2. O menu lateral é exibido e contém o item "Clientes".
3. Clicar em "Clientes" navega para a action Index do ClientesController e renderiza Views/Clientes/Index.cshtml.
4. Partial views (_Sidebar, _Navbar, _Footer) existem e são utilizadas pelo _Layout.
5. Não são necessárias alterações em arquivos estáticos do projeto (uso de CDN).

Referências
----------
- AdminLTE v4 (documentação): https://adminlte.io/themes/v4/docs/introduction.html
- Local do controller: src/GerenciamentoCliente.Adm/Controllers/ClientesController.cs




# Tasks: integrar-adminlte-cdn-aspnet-mvc

## Progress
- [x] Criar layout principal (Views/Shared/_Layout.cshtml)
- [x] Criar partials (Views/Shared/_Navbar.cshtml, _Sidebar.cshtml, _Footer.cshtml)
- [x] Aplicar layout global (Views/_ViewStart.cshtml)
- [x] Criar view de exemplo para Clientes (Views/Clientes/Index.cshtml — já existente no projeto)
- [ ] Testar navegação
- [ ] Ajustes opcionais
- [ ] Commit e descrição


Checklist de implementação (passo-a-passo)
-----------------------------------------
1. Criar layout principal
   - Caminho: Views/Shared/_Layout.cshtml
   - Conteúdo: includes CDN (Bootstrap, FontAwesome, AdminLTE), chamadas para partials (_Navbar, _Sidebar, _Footer), @RenderBody(), seções opcionais "Styles" e "Scripts".

2. Criar partials
   - Views/Shared/_Navbar.cshtml (barra superior simples)
   - Views/Shared/_Sidebar.cshtml (menu lateral com link para Clientes usando @Url.Action("Index", "Clientes"))
   - Views/Shared/_Footer.cshtml (rodapé)

3. Aplicar layout global
   - Editar ou criar Views/_ViewStart.cshtml com: @{ Layout = "~/Views/Shared/_Layout.cshtml"; }

4. Criar view de exemplo para Clientes
   - Caminho: Views/Clientes/Index.cshtml
   - Estrutura: usar seção PageHeader para título/breadcrumb e conteúdo dentro do container AdminLTE

5. Testar navegação
   - Iniciar a aplicação
   - Abrir a rota /Clientes (ou navegar via menu lateral clicando em "Clientes")
   - Verificar se a view é exibida dentro do layout AdminLTE

6. Ajustes opcionais
   - Realçar item do menu ativo (comparar controller/action atual e aplicar classe "active")
   - Incluir scripts adicionais do AdminLTE se utilizar plugins específicos (charts, datatables)

7. Commit e descrição
   - Mensagem sugerida: feat(integrar-adminlte): integrar AdminLTE v4 via CDN e layout compartilhado
   - Incluir trailer: Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>

Conteúdos de exemplo rápidos (copiar/colar)
------------------------------------------
_ViewStart.cshtml:
@{
    Layout = "~/Views/Shared/_Layout.cshtml";
}

Views/Clientes/Index.cshtml (exemplo):
@{
    ViewData["Title"] = "Clientes";
}

@section PageHeader {
    <h1>Clientes</h1>
}

<div class="card">
    <div class="card-body">
        <p>Lista de clientes (exemplo). Implemente o conteúdo real conforme os requisitos da aplicação.</p>
    </div>
</div>

Critérios de verificação
------------------------
- O layout carrega CSS/JS via CDN sem erros no console do navegador.
- O menu lateral aparece e contém o link "Clientes".
- A navegação do menu leva para a action Index do ClientesController.

Estimativa
----------
Tempo estimado: 30–60 minutos (dependendo de testes e ajustes visuais).

Notas
-----
- Se o projeto já tiver um _Layout ou partials, adaptar em vez de substituir; prefira criar partials novos e migrar progressivamente.
- Se a aplicação usar bundling ou pipelines que conflitam com CDNs, ajustar conforme necessário.


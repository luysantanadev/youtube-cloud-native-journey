using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace GerenciamentoCliente.Adm.Migrations
{
    /// <inheritdoc />
    public partial class Indices : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "referencia",
                table: "enderecos",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.CreateIndex(
                name: "ix_enderecos_bairro",
                table: "enderecos",
                column: "bairro")
                .Annotation("Npgsql:IndexMethod", "GIN")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "ix_enderecos_logradouro",
                table: "enderecos",
                column: "logradouro")
                .Annotation("Npgsql:IndexMethod", "GIN")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "ix_clientes_cpf",
                table: "clientes",
                column: "cpf")
                .Annotation("Npgsql:IndexMethod", "GIN")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "ix_clientes_email",
                table: "clientes",
                column: "email")
                .Annotation("Npgsql:IndexMethod", "GIN")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "ix_clientes_nomecompleto",
                table: "clientes",
                column: "nomecompleto")
                .Annotation("Npgsql:IndexMethod", "GIN")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "ix_cidades_nome",
                table: "cidades",
                column: "nome")
                .Annotation("Npgsql:IndexMethod", "GIN")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_enderecos_bairro",
                table: "enderecos");

            migrationBuilder.DropIndex(
                name: "ix_enderecos_logradouro",
                table: "enderecos");

            migrationBuilder.DropIndex(
                name: "ix_clientes_cpf",
                table: "clientes");

            migrationBuilder.DropIndex(
                name: "ix_clientes_email",
                table: "clientes");

            migrationBuilder.DropIndex(
                name: "ix_clientes_nomecompleto",
                table: "clientes");

            migrationBuilder.DropIndex(
                name: "ix_cidades_nome",
                table: "cidades");

            migrationBuilder.AlterColumn<string>(
                name: "referencia",
                table: "enderecos",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100);
        }
    }
}

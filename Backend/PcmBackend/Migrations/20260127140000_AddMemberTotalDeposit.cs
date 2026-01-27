using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PcmBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddMemberTotalDeposit : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "TotalDeposit",
                table: "358_Members",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TotalDeposit",
                table: "358_Members");
        }
    }
}

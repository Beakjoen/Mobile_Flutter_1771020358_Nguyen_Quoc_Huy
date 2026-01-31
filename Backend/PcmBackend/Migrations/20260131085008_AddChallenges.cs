using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PcmBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddChallenges : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "358_TransactionCategories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Type = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_358_TransactionCategories", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "358_Challenges",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ChallengerId = table.Column<int>(type: "int", nullable: false),
                    OpponentId = table.Column<int>(type: "int", nullable: true),
                    StakeAmount = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    WinnerId = table.Column<int>(type: "int", nullable: true),
                    Message = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    CreatedDate = table.Column<DateTime>(type: "datetime2", nullable: false),
                    AcceptedDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    FinishedDate = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_358_Challenges", x => x.Id);
                    table.ForeignKey(
                        name: "FK_358_Challenges_358_Members_ChallengerId",
                        column: x => x.ChallengerId,
                        principalTable: "358_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_358_Challenges_358_Members_OpponentId",
                        column: x => x.OpponentId,
                        principalTable: "358_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_358_Challenges_358_Members_WinnerId",
                        column: x => x.WinnerId,
                        principalTable: "358_Members",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });
            migrationBuilder.CreateIndex(
                name: "IX_358_Challenges_ChallengerId",
                table: "358_Challenges",
                column: "ChallengerId");
            migrationBuilder.CreateIndex(
                name: "IX_358_Challenges_OpponentId",
                table: "358_Challenges",
                column: "OpponentId");
            migrationBuilder.CreateIndex(
                name: "IX_358_Challenges_WinnerId",
                table: "358_Challenges",
                column: "WinnerId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "358_Challenges");
            migrationBuilder.DropTable(name: "358_TransactionCategories");
        }
    }
}

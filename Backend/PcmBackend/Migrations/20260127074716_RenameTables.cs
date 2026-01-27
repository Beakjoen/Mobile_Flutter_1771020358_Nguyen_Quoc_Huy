using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PcmBackend.Migrations
{
    /// <inheritdoc />
    public partial class RenameTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_001_Bookings_001_Courts_CourtId",
                table: "001_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_001_Bookings_001_Members_MemberId",
                table: "001_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_001_Bookings_001_WalletTransactions_TransactionId",
                table: "001_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_001_Matches_001_Tournaments_TournamentId",
                table: "001_Matches");

            migrationBuilder.DropForeignKey(
                name: "FK_001_Members_AspNetUsers_UserId",
                table: "001_Members");

            migrationBuilder.DropForeignKey(
                name: "FK_001_Notifications_001_Members_ReceiverId",
                table: "001_Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_001_TournamentParticipants_001_Members_MemberId",
                table: "001_TournamentParticipants");

            migrationBuilder.DropForeignKey(
                name: "FK_001_TournamentParticipants_001_Tournaments_TournamentId",
                table: "001_TournamentParticipants");

            migrationBuilder.DropForeignKey(
                name: "FK_001_WalletTransactions_001_Members_MemberId",
                table: "001_WalletTransactions");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_WalletTransactions",
                table: "001_WalletTransactions");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_Tournaments",
                table: "001_Tournaments");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_TournamentParticipants",
                table: "001_TournamentParticipants");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_Notifications",
                table: "001_Notifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_News",
                table: "001_News");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_Members",
                table: "001_Members");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_Matches",
                table: "001_Matches");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_Courts",
                table: "001_Courts");

            migrationBuilder.DropPrimaryKey(
                name: "PK_001_Bookings",
                table: "001_Bookings");

            migrationBuilder.RenameTable(
                name: "001_WalletTransactions",
                newName: "358_WalletTransactions");

            migrationBuilder.RenameTable(
                name: "001_Tournaments",
                newName: "358_Tournaments");

            migrationBuilder.RenameTable(
                name: "001_TournamentParticipants",
                newName: "358_TournamentParticipants");

            migrationBuilder.RenameTable(
                name: "001_Notifications",
                newName: "358_Notifications");

            migrationBuilder.RenameTable(
                name: "001_News",
                newName: "358_News");

            migrationBuilder.RenameTable(
                name: "001_Members",
                newName: "358_Members");

            migrationBuilder.RenameTable(
                name: "001_Matches",
                newName: "358_Matches");

            migrationBuilder.RenameTable(
                name: "001_Courts",
                newName: "358_Courts");

            migrationBuilder.RenameTable(
                name: "001_Bookings",
                newName: "358_Bookings");

            migrationBuilder.RenameIndex(
                name: "IX_001_WalletTransactions_MemberId",
                table: "358_WalletTransactions",
                newName: "IX_358_WalletTransactions_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_001_TournamentParticipants_TournamentId",
                table: "358_TournamentParticipants",
                newName: "IX_358_TournamentParticipants_TournamentId");

            migrationBuilder.RenameIndex(
                name: "IX_001_TournamentParticipants_MemberId",
                table: "358_TournamentParticipants",
                newName: "IX_358_TournamentParticipants_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_001_Notifications_ReceiverId",
                table: "358_Notifications",
                newName: "IX_358_Notifications_ReceiverId");

            migrationBuilder.RenameIndex(
                name: "IX_001_Members_UserId",
                table: "358_Members",
                newName: "IX_358_Members_UserId");

            migrationBuilder.RenameIndex(
                name: "IX_001_Matches_TournamentId",
                table: "358_Matches",
                newName: "IX_358_Matches_TournamentId");

            migrationBuilder.RenameIndex(
                name: "IX_001_Bookings_TransactionId",
                table: "358_Bookings",
                newName: "IX_358_Bookings_TransactionId");

            migrationBuilder.RenameIndex(
                name: "IX_001_Bookings_MemberId",
                table: "358_Bookings",
                newName: "IX_358_Bookings_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_001_Bookings_CourtId",
                table: "358_Bookings",
                newName: "IX_358_Bookings_CourtId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_WalletTransactions",
                table: "358_WalletTransactions",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_Tournaments",
                table: "358_Tournaments",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_TournamentParticipants",
                table: "358_TournamentParticipants",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_Notifications",
                table: "358_Notifications",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_News",
                table: "358_News",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_Members",
                table: "358_Members",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_Matches",
                table: "358_Matches",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_Courts",
                table: "358_Courts",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_358_Bookings",
                table: "358_Bookings",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_358_Bookings_358_Courts_CourtId",
                table: "358_Bookings",
                column: "CourtId",
                principalTable: "358_Courts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_358_Bookings_358_Members_MemberId",
                table: "358_Bookings",
                column: "MemberId",
                principalTable: "358_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_358_Bookings_358_WalletTransactions_TransactionId",
                table: "358_Bookings",
                column: "TransactionId",
                principalTable: "358_WalletTransactions",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_358_Matches_358_Tournaments_TournamentId",
                table: "358_Matches",
                column: "TournamentId",
                principalTable: "358_Tournaments",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_358_Members_AspNetUsers_UserId",
                table: "358_Members",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_358_Notifications_358_Members_ReceiverId",
                table: "358_Notifications",
                column: "ReceiverId",
                principalTable: "358_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_358_TournamentParticipants_358_Members_MemberId",
                table: "358_TournamentParticipants",
                column: "MemberId",
                principalTable: "358_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_358_TournamentParticipants_358_Tournaments_TournamentId",
                table: "358_TournamentParticipants",
                column: "TournamentId",
                principalTable: "358_Tournaments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_358_WalletTransactions_358_Members_MemberId",
                table: "358_WalletTransactions",
                column: "MemberId",
                principalTable: "358_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_358_Bookings_358_Courts_CourtId",
                table: "358_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_358_Bookings_358_Members_MemberId",
                table: "358_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_358_Bookings_358_WalletTransactions_TransactionId",
                table: "358_Bookings");

            migrationBuilder.DropForeignKey(
                name: "FK_358_Matches_358_Tournaments_TournamentId",
                table: "358_Matches");

            migrationBuilder.DropForeignKey(
                name: "FK_358_Members_AspNetUsers_UserId",
                table: "358_Members");

            migrationBuilder.DropForeignKey(
                name: "FK_358_Notifications_358_Members_ReceiverId",
                table: "358_Notifications");

            migrationBuilder.DropForeignKey(
                name: "FK_358_TournamentParticipants_358_Members_MemberId",
                table: "358_TournamentParticipants");

            migrationBuilder.DropForeignKey(
                name: "FK_358_TournamentParticipants_358_Tournaments_TournamentId",
                table: "358_TournamentParticipants");

            migrationBuilder.DropForeignKey(
                name: "FK_358_WalletTransactions_358_Members_MemberId",
                table: "358_WalletTransactions");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_WalletTransactions",
                table: "358_WalletTransactions");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_Tournaments",
                table: "358_Tournaments");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_TournamentParticipants",
                table: "358_TournamentParticipants");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_Notifications",
                table: "358_Notifications");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_News",
                table: "358_News");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_Members",
                table: "358_Members");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_Matches",
                table: "358_Matches");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_Courts",
                table: "358_Courts");

            migrationBuilder.DropPrimaryKey(
                name: "PK_358_Bookings",
                table: "358_Bookings");

            migrationBuilder.RenameTable(
                name: "358_WalletTransactions",
                newName: "001_WalletTransactions");

            migrationBuilder.RenameTable(
                name: "358_Tournaments",
                newName: "001_Tournaments");

            migrationBuilder.RenameTable(
                name: "358_TournamentParticipants",
                newName: "001_TournamentParticipants");

            migrationBuilder.RenameTable(
                name: "358_Notifications",
                newName: "001_Notifications");

            migrationBuilder.RenameTable(
                name: "358_News",
                newName: "001_News");

            migrationBuilder.RenameTable(
                name: "358_Members",
                newName: "001_Members");

            migrationBuilder.RenameTable(
                name: "358_Matches",
                newName: "001_Matches");

            migrationBuilder.RenameTable(
                name: "358_Courts",
                newName: "001_Courts");

            migrationBuilder.RenameTable(
                name: "358_Bookings",
                newName: "001_Bookings");

            migrationBuilder.RenameIndex(
                name: "IX_358_WalletTransactions_MemberId",
                table: "001_WalletTransactions",
                newName: "IX_001_WalletTransactions_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_358_TournamentParticipants_TournamentId",
                table: "001_TournamentParticipants",
                newName: "IX_001_TournamentParticipants_TournamentId");

            migrationBuilder.RenameIndex(
                name: "IX_358_TournamentParticipants_MemberId",
                table: "001_TournamentParticipants",
                newName: "IX_001_TournamentParticipants_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_358_Notifications_ReceiverId",
                table: "001_Notifications",
                newName: "IX_001_Notifications_ReceiverId");

            migrationBuilder.RenameIndex(
                name: "IX_358_Members_UserId",
                table: "001_Members",
                newName: "IX_001_Members_UserId");

            migrationBuilder.RenameIndex(
                name: "IX_358_Matches_TournamentId",
                table: "001_Matches",
                newName: "IX_001_Matches_TournamentId");

            migrationBuilder.RenameIndex(
                name: "IX_358_Bookings_TransactionId",
                table: "001_Bookings",
                newName: "IX_001_Bookings_TransactionId");

            migrationBuilder.RenameIndex(
                name: "IX_358_Bookings_MemberId",
                table: "001_Bookings",
                newName: "IX_001_Bookings_MemberId");

            migrationBuilder.RenameIndex(
                name: "IX_358_Bookings_CourtId",
                table: "001_Bookings",
                newName: "IX_001_Bookings_CourtId");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_WalletTransactions",
                table: "001_WalletTransactions",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_Tournaments",
                table: "001_Tournaments",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_TournamentParticipants",
                table: "001_TournamentParticipants",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_Notifications",
                table: "001_Notifications",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_News",
                table: "001_News",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_Members",
                table: "001_Members",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_Matches",
                table: "001_Matches",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_Courts",
                table: "001_Courts",
                column: "Id");

            migrationBuilder.AddPrimaryKey(
                name: "PK_001_Bookings",
                table: "001_Bookings",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_001_Bookings_001_Courts_CourtId",
                table: "001_Bookings",
                column: "CourtId",
                principalTable: "001_Courts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_001_Bookings_001_Members_MemberId",
                table: "001_Bookings",
                column: "MemberId",
                principalTable: "001_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_001_Bookings_001_WalletTransactions_TransactionId",
                table: "001_Bookings",
                column: "TransactionId",
                principalTable: "001_WalletTransactions",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_001_Matches_001_Tournaments_TournamentId",
                table: "001_Matches",
                column: "TournamentId",
                principalTable: "001_Tournaments",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_001_Members_AspNetUsers_UserId",
                table: "001_Members",
                column: "UserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_001_Notifications_001_Members_ReceiverId",
                table: "001_Notifications",
                column: "ReceiverId",
                principalTable: "001_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_001_TournamentParticipants_001_Members_MemberId",
                table: "001_TournamentParticipants",
                column: "MemberId",
                principalTable: "001_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_001_TournamentParticipants_001_Tournaments_TournamentId",
                table: "001_TournamentParticipants",
                column: "TournamentId",
                principalTable: "001_Tournaments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_001_WalletTransactions_001_Members_MemberId",
                table: "001_WalletTransactions",
                column: "MemberId",
                principalTable: "001_Members",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}

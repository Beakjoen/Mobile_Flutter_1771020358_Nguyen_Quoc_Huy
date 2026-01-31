-- Chạy trên VPS: sqlcmd -S localhost -U sa -P 'MatKhauSA_CuaVPS' -i deploy-vps-sql.sql
-- Hoặc copy nội dung vào sqlcmd rồi gõ GO sau từng khối.

CREATE DATABASE PcmDb_358;
GO

CREATE LOGIN Login_ProjectB WITH PASSWORD = 'MatKhauProjectB@123';
GO

USE PcmDb_358;
CREATE USER User_ProjectB FOR LOGIN Login_ProjectB;
ALTER ROLE db_owner ADD MEMBER User_ProjectB;
GO

QUIT

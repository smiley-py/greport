create Proc [dbo].[sp_get_data]
AS
BEGIN
	truncate table bulletin;
	truncate table CategorizedView;

	insert into bulletin 
		select * from django_db.dbo.bulletins_bulletin WHERE 
		--( begin_time <= GETDATE() AND begin_time >= DATEADD(DAY, -21, GETDATE()))
		is_deleted=0 AND id not in (select BulletinId from CategorizedView);
	
END

exec [sp_get_data];
select * from django_db.dbo.bulletins_bulletin;
select * from bulletin
select * from CategorizedView


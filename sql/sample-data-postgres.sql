---- Insert sample data into a *clean* schema.

-- connect to db ad cmdb
\c cmdb cmdb

-- Insert role sample data
select * from core.role_insert('user', 0);
select * from core.role_insert('user', 1);
select * from core.role_insert('group', 1);
select * from core.role_insert('user', 1);
select * from core.role_insert('user', 1);
select * from core.role_insert('group', 1);
select * from core.role_insert('group', 1);
select * from core.role_insert('user', 1);

-- Insert object sample data template
-- 1
select * from core.object_insert(null, 'object', 'root object', 2);
select * from core.object_insert('my data root object', 'text', 'name', 2);
-- 3
select * from core.object_insert(null, 'object', 'racks', 1);
select * from core.object_insert('Racks', 'text', 'name', 1);
select * from core.object_insert('Server racks in computing center', 'text', 'description', 1);
-- 6
select * from core.object_insert(null, 'object', 'servers', 1);
select * from core.object_insert('Servers', 'text', 'name', 1);
select * from core.object_insert('Servers in computing center', 'text', 'description', 1);
-- 9
select * from core.object_insert(null, 'object', '', 2);
select * from core.object_insert('Rack A', 'text', 'name', 2);
select * from core.object_insert('147', 'integer', 'BE', 2);

select * from core.object_insert(null, 'object', '', 2);
select * from core.object_insert('Rack B', 'text', 'name', 2);
select * from core.object_insert('120', 'integer', 'BE', 2);
-- 15
select * from core.object_insert(null, 'object', 'server #1', 4);
select * from core.object_insert(null, 'object', 'server #2', 4);
select * from core.object_insert(null, 'object', 'server #3', 4);
-- 18
select * from core.object_insert('mailsrv', 'text', 'name', 4);
select * from core.object_insert('internal mail server', 'text', 'description', 4);
select * from core.object_insert(null, 'object', 'rack', 4);
select * from core.object_insert('91', 'integer', 'position', 4);
select * from core.object_insert('3', 'integer', 'BE', 4);
-- 23
select * from core.object_insert('adsrv', 'text', 'name', 4);
select * from core.object_insert('office active directory server', 'text', 'description', 4);
select * from core.object_insert(null, 'object', 'rack', 4);
select * from core.object_insert('4', 'integer', 'position', 4);
select * from core.object_insert('3', 'integer', 'BE', 4);
-- 28
select * from core.object_insert('vpngw', 'text', 'name', 2);
select * from core.object_insert('VPN gateway for remote login', 'text', 'description', 2);
select * from core.object_insert(null, 'object', 'rack', 2);
select * from core.object_insert('34', 'integer', 'position', 2);
select * from core.object_insert('3', 'integer', 'BE', 2);
-- 33

-- Set references between new objetcs
select * from core.reference_insert(1, null, 'parent', 2);
select * from core.reference_insert(2, 1, 'parent', 2);

select * from core.reference_insert(3, 1, 'parent', 1);
select * from core.reference_insert(4, 3, 'parent', 1);
select * from core.reference_insert(5, 3, 'parent', 1);

select * from core.reference_insert(6, 1, 'parent', 1);
select * from core.reference_insert(7, 6, 'parent', 1);
select * from core.reference_insert(8, 6, 'parent', 1);

select * from core.reference_insert(9, 3, 'parent', 1);
select * from core.reference_insert(10, 9, 'parent', 2);
select * from core.reference_insert(11, 9, 'parent', 2);

select * from core.reference_insert(12, 3, 'parent', 2);
select * from core.reference_insert(13, 12, 'parent', 2);
select * from core.reference_insert(14, 12, 'parent', 2);

select * from core.reference_insert(15, 6, 'parent', 4);
select * from core.reference_insert(16, 6, 'parent', 4);
select * from core.reference_insert(17, 6, 'parent', 4);

select * from core.reference_insert(18, 15, 'parent', 4);
select * from core.reference_insert(18, 15, 'parent', 4);
select * from core.reference_insert(19, 15, 'parent', 4);
select * from core.reference_insert(20, 9, 'link', 4);
select * from core.reference_insert(21, 15, 'parent', 4);
select * from core.reference_insert(22, 15, 'parent', 4);

select * from core.reference_insert(23, 16, 'parent', 4);
select * from core.reference_insert(23, 16, 'parent', 4);
select * from core.reference_insert(24, 16, 'parent', 4);
select * from core.reference_insert(25, 9, 'link', 4);
select * from core.reference_insert(26, 16, 'parent', 4);
select * from core.reference_insert(27, 16, 'parent', 4);

select * from core.reference_insert(28, 17, 'parent', 4);
select * from core.reference_insert(28, 17, 'parent', 2);
select * from core.reference_insert(29, 17, 'parent', 2);
select * from core.reference_insert(30, 12, 'link', 2);
select * from core.reference_insert(31, 17, 'parent', 2);
select * from core.reference_insert(32, 17, 'parent', 2);

-- Adds tags to objects
select * from core.tag_insert('root', 1);
select * from core.tag_insert('server', 6);
select * from core.tag_insert('racks', 3);

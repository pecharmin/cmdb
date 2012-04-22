-- connect to db ad cmdb
\c cmdb cmdb

-- Insert role sample data
select * from core.role_insert('user');
select * from core.role_insert('user');
select * from core.role_insert('group');
select * from core.role_insert('user');
select * from core.role_insert('group');
select * from core.role_insert('group');
select * from core.role_insert('user');

-- Insert object sample data template
select * from core.object_insert(null, 'object', 'root object', 2);
select * from core.object_insert('my data root object', 'text', 'name', 2);
select * from core.object_insert(null, 'object', 'racks', 1);
select * from core.object_insert('Racks', 'text', 'name', 1);
select * from core.object_insert('Server racks in computing center', 'text', 'description', 1);
select * from core.object_insert(null, 'object', 'servers', 1);
select * from core.object_insert('Servers', 'text', 'name', 1);
select * from core.object_insert('Servers in computing center', 'text', 'description', 1);
select * from core.object_insert(null, 'object', '', 2);
select * from core.object_insert('Rack A', 'text', 'name', 2);
select * from core.object_insert('147', 'integer', 'BE', 2);
select * from core.object_insert(null, 'object', '', 2);
select * from core.object_insert('Rack B', 'text', 'name', 2);
select * from core.object_insert('120', 'integer', 'BE', 2);

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

-- Adds tags to objects
select * from core.tag_insert('root', 1);
select * from core.tag_insert('server', 6);
select * from core.tag_insert('racks', 3);

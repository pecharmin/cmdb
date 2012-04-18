---- SQL Script creates functions for CMDB core to handle data via functions

--    CMDB stores any data type in a object tree as attributes.
--    Copyright (C) 2012 Armin Pech <mail@arminpech.de>, Duesseldorf, Germany
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.


-- connect to db as right user
\connect cmdb cmdb_admin


---- object handling

-- insert object
-- Usage: core.object_insert (value, value_type, name, role_id)
-- Returns: id of new object
create or replace function core.object_insert (
	bytea,
	core.value_type_enum,
	varchar(120),
	integer
) returns bigint as $$
	insert into core.objects (
		value,
		value_type,
		name,
		version,
		mtime,
		locked_by_role_id
	) values (
		$1,
		$2,
		$3,
		1,
		now(),
		null
	);

	insert into core.objects_archive (
		id,
		value,
		value_type,
		name,
		version,
		mtime,
		modified_by_role_id
	) select
		lastval(),
		null,
		$2,
		null,
		0,
		mtime,
		$4
	from core.objects where id=lastval()
	returning lastval() as id;
$$ language sql security definer;

grant execute on function core.object_insert (bytea, core.value_type_enum, varchar(120), integer) to cmdb;


-- delete object
-- Usage: core.object_delete(id, role_id)
-- Returns: version of deleted object
create or replace function core.object_delete (
	bigint,
	integer
) returns integer as $$
	insert into core.objects_archive (
		id,
		value,
		value_type,
		name,
		version,
		mtime,
		modified_by_role_id
	) select
		id,
		value,
		value_type,
		name,
		version,
		mtime,
		$2
	from core.objects where id=$1;

	delete from core.objects where id=$1
	returning version as version;
$$ language sql security definer;

grant execute on function core.object_delete (bigint, integer) to cmdb;


-- update object
-- Usage: core.object_update(id, value, value_type, name, role_id)
-- Returns: version of new object
create or replace function core.object_update (
	bigint,
	bytea,
	core.value_type_enum,
	varchar(120),
	integer
) returns integer as $$
	insert into core.objects_archive (
		id,
		value,
		value_type,
		name,
		version,
		mtime,
		modified_by_role_id
	) select
		id,
		value,
		value_type,
		name,
		version,
		mtime,
		$5
	from core.objects where id=$1;

	update core.objects set
		value			= $2,
		value_type		= $3,
		name			= $4,
		version			= version + 1,
		mtime			= now()
	where id=$1
	returning version as version;
$$ language sql security definer;

grant execute on function core.object_update (bigint, bytea, core.value_type_enum, varchar(120), integer) to cmdb;

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


-- delete object by id
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
	from core.objects where id=$1 and locked_by_role_id is null or locked_by_role_id=$2;

	delete from core.objects where id=$1 and locked_by_role_id is null or locked_by_role_id=$2
	returning version as version;
$$ language sql security definer;

grant execute on function core.object_delete (bigint, integer) to cmdb;


-- update object by id
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
	from core.objects where id=$1 and locked_by_role_id is null or locked_by_role_id=$5;

	update core.objects set
		value			= $2,
		value_type		= $3,
		name			= $4,
		version			= version + 1,
		mtime			= now()
	where id=$1 and locked_by_role_id is null or locked_by_role_id=$5
	returning version as version;
$$ language sql security definer;

grant execute on function core.object_update (bigint, bytea, core.value_type_enum, varchar(120), integer) to cmdb;


-- select object by id
-- Usage: core.object_select(id)
-- Returns: row of core.objects table
create or replace function core.object_select (
	bigint
) returns table (
	id bigint,
	value bytea,
	value_type core.value_type_enum,
	name varchar(120),
	version integer,
	mtime timestamp without time zone,
	locked_by_role_id integer
) as $$
	select * from core.objects where id=$1;
$$ language sql security definer;

grant execute on function core.object_select (bigint) to cmdb;



---- reference handling

-- insert reference
-- Usage: core.reference_insert(object_id, refed_object_id, type, role_id)
-- Returns: object_id
create or replace function core.reference_insert (
	bigint,
	bigint,
	core.reference_type_enum,
	integer
) returns bigint as $$
	insert into core.references (
		object_id,
		referenced_object_id,
		reference_type,
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

	insert into core.references_archive (
		object_id,
		referenced_object_id,
		reference_type,
		version,
		mtime,
		modified_by_role_id
	) values (
		$1,
		$2,
		$3,
		0,
		now(),
		$4
	) returning object_id as object_id;
$$ language sql security definer;

grant execute on function core.reference_insert (bigint, bigint, core.reference_type_enum, integer) to cmdb;

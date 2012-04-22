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
create or replace function core.object_insert (
	bytea,
	core.value_type_enum,
	varchar(120),
	integer
) returns table (
	id			bigint,
	value			bytea,
	value_type		core.value_type_enum,
	name			varchar(120),
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
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
	from core.objects
	where	id=lastval();
	select
		id,
		value,
		value_type,
		name,
		version,
		mtime,
		locked_by_role_id
	from core.objects
	where	id=lastval();
$$ language sql security definer;

grant execute on function core.object_insert (bytea, core.value_type_enum, varchar(120), integer) to cmdb;


-- delete object by id
-- Usage: core.object_delete(id, role_id)
create or replace function core.object_delete (
	bigint,
	integer
) returns table (
	id			bigint,
	value			bytea,
	value_type		core.value_type_enum,
	name			varchar(120),
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
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
	from core.objects
	where	id=$1 and
		locked_by_role_id is null or
		locked_by_role_id=$2;

	delete from core.objects
	where	id=$1 and
		locked_by_role_id is null or
		locked_by_role_id=$2
	returning
		id as id,
		value as value,
		value_type as value_type,
		name as name,
		version as version,
		mtime as mtime,
		locked_by_role_id as locked_by_role_id;
$$ language sql security definer;

grant execute on function core.object_delete (bigint, integer) to cmdb;


-- update object by id
-- Usage: core.object_update(id, value, value_type, name, role_id)
create or replace function core.object_update (
	bigint,
	bytea,
	core.value_type_enum,
	varchar(120),
	integer
) returns table (
	id			bigint,
	value			bytea,
	value_type		core.value_type_enum,
	name			varchar(120),
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
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
	from core.objects
	where	id=$1 and
		locked_by_role_id is null or
		locked_by_role_id=$5;

	update core.objects set
		value			= $2,
		value_type		= $3,
		name			= $4,
		version			= version + 1,
		mtime			= now()
	where	id=$1 and
		locked_by_role_id is null or
		locked_by_role_id=$5
	returning
		id as id,
		value as value,
		value_type as value_type,
		name as name,
		version as version,
		mtime as mtime,
		locked_by_role_id as locked_by_role_id;
$$ language sql security definer;

grant execute on function core.object_update (bigint, bytea, core.value_type_enum, varchar(120), integer) to cmdb;


-- select object by id
-- Usage: core.object_select(id)
create or replace function core.object_select (
	bigint
) returns table (
	id			bigint,
	value			bytea,
	value_type		core.value_type_enum,
	name			varchar(120),
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
	select * from core.objects
	where	id=$1;
$$ language sql security definer;

grant execute on function core.object_select (bigint) to cmdb;


-- select object by tag name
-- Usage: core.object_select_tag(name)
create or replace function core.object_select_tag (
	varchar(120)
) returns table (
	id			bigint,
	value			bytea,
	value_type		core.value_type_enum,
	name			varchar(120),
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
	select o.* from core.tags t
	left join core.objects o on
		t.object_id = o.id
	where	t.name = $1;
$$ language sql security definer;

grant execute on function core.object_select_tag (varchar(120)) to cmdb;


-- select object by option name
-- Usage: core.object_select_option(name)
create or replace function core.object_select_option (
	varchar(120)
) returns table (
	id			bigint,
	value			bytea,
	value_type		core.value_type_enum,
	name			varchar(120),
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
	select ob.* from core.options op
	left join core.objects ob on
		op.object_id = ob.id
	where	op.name = $1;
$$ language sql security definer;

grant execute on function core.object_select_option (varchar(120)) to cmdb;




---- reference handling

-- insert reference
-- Usage: core.reference_insert(object_id, refed_object_id, type, role_id)
create or replace function core.reference_insert (
	bigint,
	bigint,
	core.reference_type_enum,
	integer
) returns table (
	object_id		bigint,
	referenced_object_id	bigint,
	reference_type		core.reference_type_enum,
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
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
	);
	select
		object_id,
		referenced_object_id,
		reference_type,
		version,
		mtime,
		locked_by_role_id
	from core.references
	where	object_id=$1 and
		referenced_object_id=$2 and
		reference_type=$3;
$$ language sql security definer;

grant execute on function core.reference_insert (bigint, bigint, core.reference_type_enum, integer) to cmdb;


-- update reference (non root) by object's ids and type
-- Usage: core.reference_update(object_id, new_refed_object_id, new_type, role_id)
create or replace function core.reference_update (
	bigint,
	bigint,
	core.reference_type_enum,
	integer
) returns table (
	object_id		bigint,
	referenced_object_id	bigint,
	reference_type		core.reference_type_enum,
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
	insert into core.references_archive (
		object_id,
		referenced_object_id,
		reference_type,
		version,
		mtime,
		modified_by_role_id
	) select
		object_id,
		referenced_object_id,
		reference_type,
		version,
		mtime,
		$4
	from core.references
	where	object_id=$1 and
		referenced_object_id=$2 and
		reference_type=$3 and
		locked_by_role_id is null or
		locked_by_role_id=$4;

	update core.references set
		referenced_object_id	= $2,
		reference_type		= $3,
		version			= version + 1,
		mtime			= now()
	where	object_id=$1 and
		referenced_object_id=$2 and
		reference_type=$3 and
		locked_by_role_id is null or
		locked_by_role_id=$4
	returning
		object_id as object_id,
		referenced_object_id as referenced_object_id,
		reference_type as reference_type,
		version as version,
		mtime as mtime,
		locked_by_role_id as locked_by_role_id;
$$ language sql security definer;

grant execute on function core.reference_update (bigint, bigint, core.reference_type_enum, integer) to cmdb;


-- update root reference by type
-- Usage: core.reference_update(object_id, new_reffed_object_id, new_type, role_id)
create or replace function core.reference_update_root (
	bigint,
	bigint,
	core.reference_type_enum,
	integer
) returns table (
	object_id		bigint,
	referenced_object_id	bigint,
	reference_type		core.reference_type_enum,
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
	insert into core.references_archive (
		object_id,
		referenced_object_id,
		reference_type,
		version,
		mtime,
		modified_by_role_id
	) select
		object_id,
		referenced_object_id,
		reference_type,
		version,
		mtime,
		$4
	from core.references
	where	object_id=$1 and
		referenced_object_id is null and
		reference_type=$3 and
		locked_by_role_id is null or
		locked_by_role_id=$4;

	update core.references set
		referenced_object_id	= $2,
		reference_type		= $3,
		version			= version + 1,
		mtime			= now()
	where	object_id=$1 and
		referenced_object_id is null and
		reference_type=$3 and
		locked_by_role_id is null or
		locked_by_role_id=$4
	returning
		object_id as object_id,
		referenced_object_id as referenced_object_id,
		reference_type as reference_type,
		version as version,
		mtime as mtime,
		locked_by_role_id as locked_by_role_id;
$$ language sql security definer;

grant execute on function core.reference_update_root (bigint, bigint, core.reference_type_enum, integer) to cmdb;


-- delete reference by object's ids and type
-- Usage: core.reference_delete(object_id, new_reffed_object_id, type, role_id)
create or replace function core.reference_delete (
	bigint,
	bigint,
	core.reference_type_enum,
	integer
) returns table (
	object_id		bigint,
	referenced_object_id	bigint,
	reference_type		core.reference_type_enum,
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
	insert into core.references_archive (
		object_id,
		referenced_object_id,
		reference_type,
		version,
		mtime,
		modified_by_role_id
	) select
		object_id,
		referenced_object_id,
		reference_type,
		version,
		mtime,
		$4
	from core.references
	where	object_id=$1 and
		referenced_object_id=$2 and
		reference_type=$3 and
		locked_by_role_id is null or
		locked_by_role_id=$4;

	delete from core.references
	where	object_id=$1 and
		referenced_object_id=$2 and
		reference_type=$3 and
		locked_by_role_id is null or
		locked_by_role_id=$4
	returning
		object_id as object_id,
		referenced_object_id as referenced_object_id,
		reference_type as reference_type,
		version as version,
		mtime as mtime,
		locked_by_role_id as locked_by_role_id;
$$ language sql security definer;

grant execute on function core.reference_delete (bigint, bigint, core.reference_type_enum, integer) to cmdb;


-- select references (non root) by refed object_id and type
-- Usage: core.reference_select(reffed_object_id, type)
create or replace function core.references_select (
	bigint,
	core.reference_type_enum
) returns table (
	object_id		bigint,
	referenced_object_id	bigint,
	reference_type		core.reference_type_enum,
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
	select * from core.references
	where	referenced_object_id = $1 and
		reference_type = $2;
$$ language sql security definer;

grant execute on function core.references_select (bigint, core.reference_type_enum) to cmdb;


-- select root references by type
-- Usage: core.reference_select_roots(type)
create or replace function core.references_select_root (
	core.reference_type_enum
) returns table (
	object_id		bigint,
	referenced_object_id	bigint,
	reference_type		core.reference_type_enum,
	version			integer,
	mtime			timestamp without time zone,
	locked_by_role_id	integer
) as $$
	select * from core.references
	where	referenced_object_id is null and
		reference_type = $1;
$$ language sql security definer;

grant execute on function core.references_select_root (core.reference_type_enum) to cmdb;




---- permission handling

-- add permission
-- Usage: core.permission_insert(object_id, role_id, permission, granted_by_role_id)
create or replace function core.permission_insert (
	bigint,
	integer,
	smallint,
	integer
) returns table (
	object_id		bigint,
	role_id			integer,
	permission		smallint,
	mtime			timestamp without time zone,
	granted_by_role_id	integer
) as $$
	insert into core.permissions (
		object_id,
		role_id,
		permission,
		mtime,
		granted_by_role_id
	) values (
		$1,
		$2,
		$3,
		now(),
		$4
	);

	insert into core.permissions_archive (
		object_id,
		role_id,
		permission,
		mtime,
		granted_by_role_id
	) select
		object_id,
		role_id,
		permission,
		mtime,
		granted_by_role_id
	from core.permissions
	where	object_id = $1 and
		role_id = $2
	returning
		object_id as object_id,
		role_id as role_id,
		permission as permission,
		mtime as mtime,
		granted_by_role_id as granted_by_role_id;
$$ language sql security definer;

grant execute on function core.permission_insert (bigint, integer, smallint, integer) to cmdb;


-- update permission
-- Usage: core.permission_update(object_id, role_id, changed_by_role_id)
create or replace function core.permission_update (
	bigint,
	integer,
	smallint,
	integer
) returns table (
	object_id		bigint,
	role_id			integer,
	permission		smallint,
	mtime			timestamp without time zone,
	granted_by_role_id	integer
) as $$
	insert into core.permissions_archive (
		object_id,
		role_id,
		permission,
		mtime,
		granted_by_role_id
	) select
		object_id,
		role_id,
		permission,
		mtime,
		granted_by_role_id
	from core.permissions
	where	object_id = $1 and
		role_id = $2;

	update core.permissions set
		object_id		= $1,
		role_id			= $2,
		permission		= $3,
		mtime			= now(),
		granted_by_role_id	= $4
	where	object_id = $1 and
		role_id	= $2
	returning
		object_id as object_id,
		role_id as role_id,
		permission as permission,
		mtime as mtime,
		granted_by_role_id as granted_by_role_id;
$$ language sql security definer;

grant execute on function core.permission_update (bigint, integer, smallint, integer) to cmdb;


-- delete permission
-- Usage: core.permission_delete(object_id, role_id, deleted_by_role_id)
create or replace function core.permission_delete (
	bigint,
	integer,
	integer
) returns table (
	object_id		bigint,
	role_id			integer,
	permission		smallint,
	mtime			timestamp without time zone,
	granted_by_role_id	integer
) as $$
	insert into core.permissions_archive (
		object_id,
		role_id,
		permission,
		mtime,
		granted_by_role_id
	) select
		object_id,
		role_id,
		permission,
		mtime,
		$3
	from core.permissions
	where	object_id = $1 and
		role_id = $2;

	delete from core.permissions
	where	object_id = $1 and
		role_id = $2
	returning
		object_id as object_id,
		role_id as role_id,
		permission as permission,
		mtime as mtime,
		granted_by_role_id as granted_by_role_id;
$$ language sql security definer;

grant execute on function core.permission_delete (bigint, integer, integer) to cmdb;


-- select permission by object_id
-- Usage: core.permission_select(object_id)
-- Return: row in core.permissions table format
create or replace function core.permission_select (
	bigint
) returns table (
	object_id		bigint,
	role_id			integer,
	permission		smallint,
	mtime			timestamp without time zone,
	granted_by_role_id	integer
) as $$
	select * from core.permissions
	where	object_id = $1;
$$ language sql security definer;

grant execute on function core.permission_select (bigint) to cmdb;




---- option handling

-- add option
-- Usage: core.option_insert(name, object_id)
create or replace function core.option_insert (
	varchar(120),
	bigint
) returns table (
	name		varchar(120),
	object_id	bigint
) as $$
	insert into core.options (
		name,
		object_id
	) values (
		$1,
		$2
	) returning
		name as name,
		object_id as object_id;
$$ language sql security definer;

grant execute on function core.option_insert (varchar(120), bigint) to cmdb;


-- delete option by name
-- Usage: core.options_delete(name)
create or replace function core.option_delete (
	varchar(120)
) returns table (
	name		varchar(120),
	object_id	bigint
) as $$
	delete from core.options
		where name = $1
	returning
		name as name,
		object_id as object_id;
$$ language sql security definer;

grant execute on function core.option_delete (varchar(120)) to cmdb;


-- select option by name
-- Usage: core.option_select(name)
create or replace function core.option_select(
	varchar(120)
) returns table (
	name		varchar(120),
	object_id	bigint
) as $$
	select * from core.options
	where	name = $1;
$$ language sql security definer;

grant execute on function core.option_select (varchar(120)) to cmdb;


-- select all options
-- Usage: core.option_select_all()
create or replace function core.option_select_all(
) returns table (
	name		varchar(120),
	object_id	bigint
) as $$
	select * from core.options;
$$ language sql security definer;

grant execute on function core.option_select_all () to cmdb;




---- tag handling

-- add tag to an object
-- Usage: core.tag_insert(name, object_id)
create or replace function core.tag_insert (
	varchar(120),
	bigint
) returns table (
	name		varchar(120),
	object_id	bigint
) as $$
	insert into core.tags (
		name,
		object_id
	) values (
		$1,
		$2
	) returning
		name as name,
		object_id as object_id;
$$ language sql security definer;

grant execute on function core.tag_insert (varchar(120), bigint) to cmdb;


-- delete tag by name
-- Usage: core.tag_delete(name)
create or replace function core.tag_delete (
	varchar(120)
) returns table (
	name		varchar(120),
	object_id	bigint
) as $$
	delete from core.tags
		where name = $1
	returning
		name as name,
		object_id as object_id;
$$ language sql security definer;

grant execute on function core.tag_delete (varchar(120)) to cmdb;


-- select tag by name
-- Usage: core.tag_select(tag_name)
create or replace function core.tag_select(
	varchar(120)
) returns table (
	name		varchar(120),
	object_id	bigint
) as $$
	select * from core.tags
	where	name = $1;
$$ language sql security definer;

grant execute on function core.tag_select (varchar(120)) to cmdb;


-- display all tags
-- Usage: core.tag_select_all()
create or replace function core.tag_select_all (
) returns table (
	name		varchar(120),
	object_id	bigint
) as $$
	select * from core.tags;
$$ language sql security definer;

grant execute on function core.tag_select_all () to cmdb;




---- role & membership handling

-- insert new role
-- Usage: core.role_insert(type, created_by_role_id)
create or replace function core.role_insert (
	core.role_type_enum,
	integer
) returns table (
	id			integer,
	role_type		core.role_type_enum,
	ctime			timestamp without time zone,
	created_by_role_id	integer
) as $$
	insert into core.roles (
		role_type,
		ctime,
		created_by_role_id
	) values (
		$1,
		now(),
		$2
	) returning
		cast(lastval() as integer) as id,
		$1 as role_type,
		ctime as ctime,
		created_by_role_id as created_by_role_id;
$$ language sql security definer;

grant execute on function core.role_insert (core.role_type_enum) to cmdb;

-- select role by id
-- Usage: core.role_select(id)
create or replace function core.role_select (
	integer
) returns table (
	id			integer,
	role_type		core.role_type_enum,
	ctime			timestamp without time zone,
	created_by_role_id	integer
) as $$
	select * from core.roles
	where	id = $1;
$$ language sql security definer;

grant execute on function core.role_select (integer) to cmdb;


-- grant role to role
-- Usage: core.role_membership_insert(role_id, granted_role_id, granted_by_role_id)
create or replace function core.role_membership_insert (
	integer,
	integer,
	integer
) returns table (
	role_id			integer,
	granted_role_id		integer,
	gtime			timestamp without time zone,
	granted_by_role_id	integer
) as $$
	insert into core.roles_membership (
		role_id,
		granted_role_id,
		gtime,
		granted_by_role_id
	) values (
		$1,
		$2,
		now(),
		$3
	);

	insert into core.roles_membership_archive (
		role_id,
		granted_role_id,
		gtime,
		granted_by_role_id,
		grant_type
	) select
		role_id,
		granted_role_id,
		gtime,
		granted_by_role_id,
		'grant'
	from core.roles_membership
	where	role_id = $1 and
		granted_role_id = $2
	returning
		role_id as role_id,
		granted_role_id as granted_role_id,
		gtime as gtime,
		granted_by_role_id as granted_by_role_id;
$$ language sql security definer;

grant execute on function core.role_membership_insert (integer, integer, integer) to cmdb;


-- revoke role from role
-- Usage: core.role_membership_delete(role_id, revoked_role_id, granted_by_role_id)
create or replace function core.role_membership_delete (
	integer,
	integer,
	integer
) returns table (
	role_id			integer,
	granted_role_id		integer,
	gtime			timestamp without time zone,
	granted_by_role_id	integer
) as $$
	insert into core.roles_membership_archive (
		role_id,
		granted_role_id,
		gtime,
		granted_by_role_id,
		grant_type
	) select
		role_id,
		granted_role_id,
		gtime,
		$3,
		'revoke'
	from core.roles_membership
	where	role_id = $1 and
		granted_role_id = $2;

	delete from core.roles_membership
	where	role_id = $1 and
		granted_role_id = $2
	returning
		role_id as role_id,
		granted_role_id as granted_role_id,
		gtime as gtime,
		granted_by_role_id as granted_by_role_id;
$$ language sql security definer;

grant execute on function core.role_membership_delete (integer, integer, integer) to cmdb;


-- selects all granted roles of a role
-- Usage: core.role_membership_select(role_id)
create or replace function core.role_membership_select (
	integer
) returns table (
	role_id			integer,
	granted_role_id		integer,
	gtime			timestamp without time zone,
	granted_by_role_id	integer
) as $$
	select * from core.roles_membership
	where	role_id = $1;
$$ language sql security definer;

grant execute on function core.role_membership_select (integer) to cmdb;

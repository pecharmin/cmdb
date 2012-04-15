---- SQL Script creates needed tables for CMDB

-- value type definition for objects
create type value_type_enum as enum ('object', 'integer', 'double', 'text', 'blob');

-- link type definition for references
create type ref_type_enum as enum ('link');

-- role type definition for roles
create type role_type_enum as enum ('user', 'group');


-- objects - Stores all data in objects
create table objects (
	id		bigserial		not null	primary key,
	parent_id	numeric(20)				references id,
	value		bytea			null,
	value_type	value_type_enum		not null,
	name		varchar(80)		not null,
	version		numeric(10)		not null,
	mtime		timestamp		not null,
	role_id		numeric(10)
);

-- objects_archive - Archives modified objects as a history
create table objects_archive (
	id		bigserial		not null	references objects (id),
	parent_id	numeric(20)				references objects (id),
	value		bytea			null,
	value_type	value_type_enum		not null,
	name		varchar(80)		not null,
	version		numeric(10)		not null,
	mtime		timestamp		not null,
	role_id		numeric(10)		not null,
	atime		timestamp		not null
);


-- references - Links are not data and must not be stored for revision
create table references (
	object_id	numeric(20)		not null	references objects (id),
	ref_object_id	numeric(20)		not null	references objects (id),
	ref_type	ref_type_enum		not null
);

-- roles - Defines users and roles for permission handling
create table roles (
	id		serial			not null	primary key,
	role_type	role_type_enum		not null
);

-- roles_membership - Assigns roles to roles like groups or user cloning
create table roles_memebership (
	role_id		numeric(10)		not null	references roles (id),
	add_role_id	numeric(10)		not null	references roles (id)
);

-- permissions - Grants permissions for objects to roles
create table permissions (
	object_id	numeric(20)		not null	references objects (id),
	role_id		numeric(10)		not null	references roles (id),
	permission	numeric(4)		not null	check (permission >= 0)
);

-- permissions_audit - Save the changed permissions as a trace
create table permissions_audit (
	object_id	numeric(20)		not null	references objects (id),
	role_id		numeric(10)		not null	references roles (id),
	permission	numeric(4)		not null	check (permission >= 0)
	changed_by_role	numeric(10)		not null	references roles (id),
	atime		timestamp		not null	default now()
);

-- options - Stores application internal options
create table options (
	name		varchar(160)		not null	primary key,
	object_id	numeric(20)		not null	references objects (id)
);

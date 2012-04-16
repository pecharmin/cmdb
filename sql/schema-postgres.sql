---- SQL Script creates needed tables for CMDB

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


-- create database for application and grant to cmdb admin
create role cmdb_admin login password 'cmdb_admin';
-- cmdb database objects are owned due security reasons by another user
-- than which the application uses
create database cmdb owner cmdb_admin;

-- create user for cmdb application
create role cmdb login password 'cmdb';
grant connect on database cmdb to cmdb;


-- add schema for storing data of cmdb core
\connect cmdb
create schema core authorization cmdb_admin;
grant all privileges on schema core to cmdb_admin with grant option;
grant usage on schema core to cmdb;

-- connect as cmdb admin to create objects
\connect cmdb cmdb_admin


-- value type definition for objects
create type core.value_type_enum as enum ('object', 'integer', 'double', 'text', 'blob');

-- role type definition for roles
create type core.role_type_enum as enum ('user', 'group');

-- reference type definition for references table
create type core.reference_type_enum as enum ('parent', 'link');


-- roles - Defines users and groups as roles for permission handling
create table core.roles (
	id			serial			not null	primary key,
	role_type		core.role_type_enum	not null
);

-- roles_membership - Assigns roles to roles like grouping or user cloning
create table core.roles_membership (
	role_id			integer			not null	references core.roles (id),
	granted_role_id		integer			not null	references core.roles (id)
);


-- objects - Stores all data in objects
create table core.objects (
	id			bigserial		not null	primary key,
	value			bytea			null		default null,
	value_type		core.value_type_enum	not null,
	name			varchar(120)		not null,
	version			integer			not null,
	mtime			timestamp		not null,
	locked_by_role_id	integer			null		references core.roles (id) default null
);

-- objects_archive - Archives modified objects as a history
create table core.objects_archive (
	id			bigint			not null,
	value			bytea			null,
	value_type		core.value_type_enum	not null,
	name			varchar(120)		not null,
	version			integer			not null,
	mtime			timestamp		not null,
	modified_by_role_id	integer			not null	references core.roles (id)
);


-- references - Links the objects togehter
create table core.references (
	object_id		bigint			not null	references core.objects (id),
	referenced_object_id	bigint			null		references core.objects (id),
	reference_type		core.reference_type_enum not null,
	version			integer			not null,
	mtime			timestamp		not null,
	locked_by_role_id	integer			null		references core.roles (id) default null,
	primary key(object_id, referenced_object_id, reference_type)
);

-- references_archive - Archives all modified references
create table core.references_archive (
	object_id		bigint			not null,
	referenced_object_id	bigint			null,
	reference_type		core.reference_type_enum not null,
	version			integer			not null,
	mtime			timestamp		not null,
	modified_by_role_id	integer			not null	references core.roles (id)
);


-- permissions - Grants permissions for objects to roles
create table core.permissions (
	object_id		bigint			not null	references core.objects (id),
	role_id			integer			not null	references core.roles (id),
	permission		smallint		not null	check (permission >= 0) default 0,
	mtime			timestamp		not null,
	granted_by_role_id	integer			not null	references core.roles (id),
	primary key(object_id, role_id)
);

-- permissions_audit - Save the changed permissions as a audit
create table core.permissions_archive (
	object_id		bigint			not null,
	role_id			integer			not null	references core.roles (id),
	permission		smallint		not null	check (permission >= 0),
	mtime			timestamp		not null,
	granted_by_role_id	integer			not null	references core.roles (id)
);


-- options - Stores application internal options with human readable names
create table core.options (
	name			varchar(120)		not null	primary key,
	object_id		bigint			not null	references core.objects (id)
);


-- tags - Adds unique tag names to an object for human identification
create table core.tags (
	name			varchar(120)		not null	primary key,
	object_id		bigint			not null	references core.objects (id)
);

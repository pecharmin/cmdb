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


-- create schema and grant to cmdb admin
create role cmdb_admin login password 'cmdb_admin';
create database cmdb owner cmdb_admin;
grant all privileges on database cmdb to cmdb_admin with grant option;

-- create user for cmdb application
create role cmdb login password 'cmdb';
grant connect on database cmdb to cmdb;


-- value type definition for objects
create type value_type_enum as enum ('object', 'integer', 'double', 'text', 'blob', 'link', 'child');

-- role type definition for roles
create type role_type_enum as enum ('user', 'group');


-- objects - Stores all data in objects
create table objects (
	id		bigserial		not null	primary key,
	parent_id	bigint			null		references objects (id),
	value		bytea			null		default null,
	value_type	value_type_enum		not null,
	name		varchar(80)		not null,
	version		integer			not null,
	mtime		timestamp		not null,
	role_id		integer			null		default null
);

-- objects_archive - Archives modified objects as a history
create table objects_archive (
	id		bigint			not null	references objects (id),
	parent_id	bigint			null		references objects (id),
	value		bytea			null		default null,
	value_type	value_type_enum		not null,
	name		varchar(80)		not null,
	version		integer			not null,
	mtime		timestamp		not null,
	role_id		integer			not null,
	atime		timestamp		not null
);


-- roles - Defines users and roles for permission handling
create table roles (
	id		serial			not null	primary key,
	role_type	role_type_enum		not null
);

-- roles_membership - Assigns roles to roles like groups or user cloning
create table roles_memebership (
	role_id		integer			not null	references roles (id),
	add_role_id	integer			not null	references roles (id)
);

-- permissions - Grants permissions for objects to roles
create table permissions (
	object_id	bigint			not null	references objects (id),
	role_id		integer			not null	references roles (id),
	permission	smallint		not null	check (permission >= 0) default 0
);

-- permissions_audit - Save the changed permissions as a trace
create table permissions_audit (
	object_id	bigint			not null	references objects (id),
	role_id		integer			not null	references roles (id),
	permission	smallint		not null	check (permission >= 0),
	changed_by_role	integer			not null	references roles (id),
	atime		timestamp		not null	default now()
);


-- options - Stores application internal options
create table options (
	name		varchar(160)		not null	primary key,
	object_id	bigint			not null	references objects (id)
);

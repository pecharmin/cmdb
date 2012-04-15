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


---- object handling

-- insert object
-- Usage: core.object_insert (value, value_type, name, role_id)
-- Returns: id of new object
create function core.object_insert (
	bytea,
	varchar(10),
	varchar(80),
	integer
) returns bigint as $$
	insert into core.objects (
		value,
		value_type,
		name,
		version,
		mtime
	) values (
		$1,
		$2,
		$3,
		1,
		now()
	);
	insert into core.objects_archive select
		id,
		value,
		value_type,
		name,
		version,
		mtime,
		$4,
		mtime
	from core.objects where id=lastval()
	returning lastval() as id;
$$ language sql;

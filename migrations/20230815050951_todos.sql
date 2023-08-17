-- Add migration script here
create table if not exists todos(
    id integer primary key AUTOINCREMENT,
    description text not null,
    done boolean not null default 0
);
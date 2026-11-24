create table public.player_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  checkpoint smallint not null check (checkpoint between 0 and 3),
  updated_at timestamptz not null default now()
);

alter table public.player_progress enable row level security;
revoke all on public.player_progress from public, anon, authenticated;
grant select on public.player_progress to authenticated;

create policy "Jogador lê o próprio progresso"
  on public.player_progress for select to authenticated
  using ((select auth.uid()) = user_id);

create function public.save_player_checkpoint(player_id uuid, reached_checkpoint integer)
returns smallint
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_player uuid := auth.uid();
  saved_checkpoint smallint;
begin
  if current_player is null or player_id is distinct from current_player then
    raise exception 'Sessão inválida para este jogador' using errcode = '42501';
  end if;

  if reached_checkpoint is null or reached_checkpoint not between 0 and 3 then
    raise exception 'Ponto de controlo inválido' using errcode = '22023';
  end if;

  insert into public.player_progress as progress (user_id, checkpoint)
  values (current_player, reached_checkpoint)
  on conflict (user_id) do update
    set checkpoint = greatest(progress.checkpoint, excluded.checkpoint),
        updated_at = case when excluded.checkpoint > progress.checkpoint then now()
                          else progress.updated_at end
  returning checkpoint into saved_checkpoint;

  return saved_checkpoint;
end;
$$;

revoke all on function public.save_player_checkpoint(uuid, integer) from public, anon, authenticated;
grant execute on function public.save_player_checkpoint(uuid, integer) to authenticated;

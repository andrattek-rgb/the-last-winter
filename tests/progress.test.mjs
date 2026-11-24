import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { PGlite } from "@electric-sql/pglite";
import { createProgressQueue, isCheckpoint } from "../web/progress.js";

test("a fila recupera de falhas e guarda o ponto mais recente da conta", async () => {
  const userId = "a";
  const requests = [];
  const notices = [];
  let fail = true;
  const client = {
    async rpc(name, data) {
      assert.equal(name, "save_player_checkpoint");
      assert.equal(data.player_id, userId);
      requests.push(data.reached_checkpoint);
      return fail ? { error: true } : { data: data.reached_checkpoint };
    },
  };
  const queue = createProgressQueue(client, userId, 0, (state) => notices.push(state));
  queue.reach(1);
  queue.reach(2);
  queue.reach(4);
  await new Promise(setImmediate);
  assert.equal(queue.hasPending(), true);
  assert.equal(notices.at(-1), "error");
  fail = false;
  await queue.retry();
  queue.reach(1);
  assert.deepEqual(requests, [1, 2]);
  assert.equal(queue.hasPending(), false);
  assert.equal(notices.at(-1), "saved");
  assert.equal(isCheckpoint("3"), false);
});

test("a migração protege a leitura e a gravação e impede recuos", async () => {
  const db = new PGlite();
  const one = "00000000-0000-4000-8000-000000000001";
  const two = "00000000-0000-4000-8000-000000000002";
  const save = (user, stage) => db.query("select public.save_player_checkpoint($1, $2) as checkpoint", [user, stage]);
  const identity = (user) => db.query("select set_config('request.jwt.claim.sub', $1, false)", [user]);
  try {
    await db.exec(`
      create role anon;
      create role authenticated;
      create schema auth;
      create table auth.users (id uuid primary key);
      create function auth.uid() returns uuid language sql stable
        as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
      grant usage on schema auth to authenticated;
      insert into auth.users values ('${one}'), ('${two}');
    `);
    await db.exec(await readFile(new URL("../supabase/migrations/202611240001_player_progress.sql", import.meta.url), "utf8"));
    await db.exec("set role anon");
    await assert.rejects(save(one, 0), { code: "42501" });
    await assert.rejects(db.query("select * from public.player_progress"), { code: "42501" });
    await db.exec("set role authenticated");
    await assert.rejects(save(one, 0), { code: "42501" });
    await identity(one);
    assert.deepEqual((await save(one, 3)).rows, [{ checkpoint: 3 }]);
    assert.deepEqual((await save(one, 1)).rows, [{ checkpoint: 3 }]);
    await assert.rejects(save(one, 4), { code: "22023" });
    await assert.rejects(db.query("update public.player_progress set checkpoint = 0"), { code: "42501" });
    await identity(two);
    assert.deepEqual((await db.query("select * from public.player_progress")).rows, []);
    await assert.rejects(save(one, 2), { code: "42501" });
    assert.deepEqual((await save(two, 1)).rows, [{ checkpoint: 1 }]);
    assert.deepEqual((await db.query("select user_id from public.player_progress")).rows, [{ user_id: two }]);
    await identity(one);
    assert.deepEqual((await db.query("select checkpoint from public.player_progress")).rows, [{ checkpoint: 3 }]);
  } finally {
    await db.close();
  }
});

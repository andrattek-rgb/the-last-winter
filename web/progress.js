export const checkpoints = ["Barracks", "First courtyard", "Kitchen", "Second courtyard"];

export function isCheckpoint(value) {
  return Number.isInteger(value) && value >= 0 && value < checkpoints.length;
}

export async function readCheckpoint(client, userId) {
  const { data, error } = await client.from("player_progress").select("checkpoint")
    .eq("user_id", userId).maybeSingle();
  if (error) throw error;
  if (data && !isCheckpoint(data.checkpoint)) throw new Error("Unknown checkpoint.");
  return data?.checkpoint ?? null;
}

export function createProgressQueue(client, userId, initial, notify) {
  let saved = initial ?? -1;
  let target = saved;
  let active = false;

  async function flush() {
    if (active || target <= saved) return;
    active = true;
    notify("saving");
    try {
      while (target > saved) {
        const reached = target;
        const { data, error } = await client.rpc("save_player_checkpoint", {
          player_id: userId,
          reached_checkpoint: reached,
        });
        if (error) throw error;
        if (!isCheckpoint(data) || data < reached) throw new Error("Save could not be confirmed.");
        saved = data;
      }
      notify("saved");
    } catch {
      notify("error");
    } finally {
      active = false;
    }
  }

  return {
    reach(value) {
      if (isCheckpoint(value)) {
        target = Math.max(target, value);
        void flush();
      }
    },
    retry: flush,
    hasPending: () => target > saved,
  };
}

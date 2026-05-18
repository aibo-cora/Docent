# Secret Sharing

Secret Sharing lets you protect a sensitive piece of information — like a password or recovery key — by splitting it into multiple pieces called shards. No single shard reveals anything on its own. You only get the original secret back when you bring enough shards together.

Think of it like a combination lock where the combination has been torn into pieces and handed to five different people. No one person can open the lock alone, but any three of them together can.

## Splitting a Secret

To protect a secret, call `split` with the text you want to secure. It returns five unique shards.

```swift
let shards = sharing.split(secret: "my-password-123")
// Returns 5 shards — distribute these to trusted people or locations
```

Store or send each shard somewhere different. A shard sitting on its own is useless — it contains no recoverable information about the original secret.

## Recovering Your Secret

To get the secret back, collect at least three shards and call `combine`.

```swift
let secret = sharing.combine(shards: [shard1, shard2, shard3])
// Returns "my-password-123" if enough shards are provided
```

You don't need all five — any three will do. If you have fewer than three, `combine` returns `nil`.

## How Many Shards Do You Need?

You need at least **3 out of 5** shards to recover the secret. This is the threshold.

- You can lose up to 2 shards and still recover the secret.
- If you lose 3 or more, the secret is gone permanently — there is no backdoor or recovery option.

## What Happens If I Lose Shards?

| Shards available | Can recover? |
|---|---|
| 5 | Yes |
| 4 | Yes |
| 3 | Yes |
| 2 | No |
| 1 | No |
| 0 | No |

If you're below the threshold, the only option is to start over — generate a new secret and distribute fresh shards.

## Is My Secret Safe?

Yes. Each shard is mathematically constructed so that it reveals nothing about the original secret on its own. Even if someone collects two shards, they gain zero information — the math guarantees this, not just practical difficulty.

The protection comes from the threshold, not from keeping the shards secret from each other. You could publish two shards publicly and the secret would still be safe.

## Who Should Hold the Shards?

Distribute shards to people or locations that don't share a single point of failure. Good options:

- Trusted family members or colleagues
- Different cloud storage accounts
- A printed copy in a physical safe
- A password manager you don't use for the secret itself

Avoid giving two shards to the same person or storing two shards on the same device.

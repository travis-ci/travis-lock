# Travis Lock

Application-level locks for use in, e.g. travis-hub.

At the moment it seems the Redlock strategy works fine as well as the
Postgresql advisory locks strategy when used with the options in the
example below.

Usage:

```
options = {
  strategy: :postgresql,
  try: true,
  transactional: false
}
Travis::Lock.exclusive('build-1', options) do
  # update build
end
```

### Doing a Rubygem release

Any tool works. The current releases were done with
[`gem-release`](https://github.com/svenfuchs/gem-release) which allows creating
a Git tag, pushing it to GitHub, building the gem and pushing it to Rubygems in
one go:

```bash
$ gem install gem-release
$ gem bump --push --tag --release
```

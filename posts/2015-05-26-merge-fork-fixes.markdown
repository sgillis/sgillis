---
title: Merge forked fixes
---

Whenever you have a problem with some open source project, there's often a good
chance that someone else has already fixed the problem you're facing on a
forked repository. This is the great thing about open source software.

However, it might happen that you need fixes from multiple forks. Or maybe you
need a fix from a fork, but the fork is horribly outdated and doesn't have the
latest fixes from the master repository. What to do in this case?

<!--more-->

Git to the rescue! You can just create your own fork that has everything you
need. So first create your own fork and clone it to your machine. Then add any
extra remote branches you need

```
git remote add <remotename> git://github.com/<user>/<reponame>.git
git fetch <remotename>
```

This will pull everything from that fork. Now we can cherry-pick any commits we
want.

```
git cherry-pick -n <commit sha1>
git commit
```

That's it. You now have your own fork with all the fixes you need. Git is a
great tool!

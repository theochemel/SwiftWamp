import sys
from autobahn import wamp
from autobahn.twisted.wamp import ApplicationSession
from twisted.internet.defer import inlineCallbacks


class OpenRealmSession(ApplicationSession):
    usernames = ["pok", "root", "Dany", "Yossi"]

    @inlineCallbacks
    def onJoin(self, details):
        try:
            yield self.register(self)
        except Exception as e:
            print("Failed to register topic in OpenRealmSession : {0}".format(e), file=sys.stderr)
        return

    @wamp.register('org.swamp.add')
    def add(self, num1, num2):
        return num1 + num2

    @wamp.register('org.swamp.echo')
    def echo(self, param1, param2):
        return param1, param2

    @wamp.register('user.username.available')
    def username_available(self, **kwargs):
        if kwargs["username"] in self.usernames:
            return False, None
        return True, None


    @wamp.register('user.username.unavailable')
    def username_unavailable(self, **kwargs):
        if kwargs["username"] in self.usernames:
            return True
        return False

from autobahn.twisted.wamp import ApplicationSession
from twisted.internet.task import LoopingCall


class LoopingPublish(ApplicationSession):
    def onJoin(self, details):
        def heartbeat():
            return self.publish(u'org.swamp.heartbeat', 'Heartbeat!')

        LoopingCall(heartbeat).start(1)

from autobahn import wamp
from autobahn.twisted.wamp import ApplicationSession
from twisted.internet.defer import inlineCallbacks


class AuthorizerSession(ApplicationSession):
    database = {
        "topic1": {
            "philippe": {
                "subscribe": True,
                "publish": False,
            },
            "bob": {
                "subscribe": True,
                "publish": True,
            },
            "bastardo": {
                "subscribe": True,
                "publish": False,
            },
            "john": {
                "subscribe": True,
                "publish": True,
            }
        },
        "topic2": {
            "bob": {
                "subscribe": True,
                "publish": True,
            },
            "john": {
                "subscribe": True,
                "publish": True,
            }
        }
    }

    @inlineCallbacks
    def onJoin(self, details):
        """
        Function called when Authorizer component is ready

        This function make all register call
        Here the authorize function is registered

        :param autobahn.wamp.types.SessionDetails details: Session information.
        """
        yield self.register(self)

    @wamp.register('authorize')
    def authorize(self, session, uri, action):
        """
        Function associated to `authorize` procedure.

        Use session["authid"] for identify the user
        Use session["authrole"] for determine the role, for the moment session['authrole'] MUST BE equal to
        the role delivered by AuthenticatorSession
        Use the uri if you need procedure name
        Use action for determine the action type (subscribe, register, publish, call)

        See Authorizer.get_subscribe_authorization

        :param dict session: Client session details
        :param string uri: Procedure name
        :param string action: Action type (subscribe, register, publish, call)
        :return : A boolean for simple usage but Authorizers can configure additional aspects, e.g. whether a caller's
        or publisher's identity is disclosed to the callee or subscribers. In this case, a dictionary is returned,
        e.g. {"allow": True, "disclose": True}.
        """
        if action == "register":
            return False
        if action == "call":
            return {"allow": True, "disclose": True}

        permissions = AuthorizerSession.get_subscribe_authorization(uri, session["authid"])

        print("permissions for " + action + ": " + str(permissions[action]))
        return {"allow": permissions[action], "disclose": True}

    def get_subscribe_authorization(self, topic_name, user_id):
        """
        Check user permission to subscribe and publish in a topic using Subscribe table.

        By default subscribe and publish permissions is set to False.
        If no entry exist for user pk and topic_name combination, all permission is False
        else the permission attribute is used to set publish (WRITE) and subscribe (READ) permission

        :param string topic_name: Topic name for permission check
        :param str user_id: User uuid
        :return:
        """
        return {
            "subscribe": self.database[topic_name][user_id]['permission'],
            "publish": False,
        }

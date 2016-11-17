from autobahn import wamp
from autobahn.twisted.wamp import ApplicationSession
from autobahn.wamp.exception import ApplicationError
from twisted.internet.defer import inlineCallbacks


class AuthenticatorSession(ApplicationSession):
    realm = "realm1"
    role = "dynamic_user"
    database = {
        "philippe": "torreton",
        "bob": "dylan",
        "bastardo": "dentro",
        "john": "butler"
    }

    @inlineCallbacks
    def onJoin(self, details):
        """
        Function called when AuthenticatorSession component is ready

        This function make all register call
        Here the authenticate function is registered

        :param autobahn.wamp.types.SessionDetails details: Session information.
        """
        yield self.register(self)

    @wamp.register('authenticate')
    def authenticate(self, realm_asked, authid, details):
        """
        Function associated to `authenticate` procedure.

        Use realm_asked for determine how permission user asked, and authid with details['ticket'] combination
        for authenticate the user. Authenticate use authenticate_user function.

        :param string realm_asked: realm asked by the client
        :param string authid: user id
        :param dict details: contain the ticket value
        :return: dictionary with authentication information
        """
        if "ticket" in details and self.authenticate_user(authid, details["ticket"]):
            if realm_asked != self.realm:
                raise ApplicationError("authenticate.invalid_realm", "Unsupported realm : {}".format(realm_asked))
            extra = {"test_extra_data": ["a", "b", "c"]}
            return self.create_auth_information(self.realm, self.role, extra)
        elif "ticket" in details:
            error_msg = "Could not authenticate session - Invalid token with authid {}".format(authid)
            raise ApplicationError("authenticate.invalid_token", error_msg)
        else:
            error_msg = "Could not authenticate session - Ticket key is missing"
            raise ApplicationError("authenticate.ticket_is_missing", error_msg)

    def authenticate_user(self, user_id, token):
        """
        Return True if Username/Token combination match in database

        :param str user_id: User id associated to token
        :param string token: Token used by the user for authorizer
        :return: Boolean, true if Username/Token combination match in database
        """

        return self.database[user_id] == token

    @staticmethod
    def create_auth_information(realm, role, extra=None):
        """
        Function to create a result dictionary for authenticate procedure

        :param string realm: The realm assigned to client
        :param string role: The role assigned to client
        :param dict extra: A dictionary for extra informations to communicate to the client
        :return:
        """
        result = {
            "realm": realm,
            "role": role,
        }
        if extra is not None:
            result["extra"] = extra

        return result

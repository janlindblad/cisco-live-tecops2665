"""NSO Nano service example.

Implements a Nano service callback
(C) 2023 Cisco Systems
Permission to use this code as a starting point hereby granted

See the README file for more information
"""
import ncs
from ncs.application import NanoService
from ncs.maapi import Maapi
from ncs.dp import Action

import traceback

class SkylightNotificationAction(ncs.dp.Action):
    @Action.action
    def cb_action(self, uinfo, name, kp, input, output, trans):
        #def cb_action(self, t, input):
        try:
            root = ncs.maagic.get_root(trans)
            notification = root._get_node(input.path)

            self.log.info(f'Got notification type {notification}')
            return True

        except Exception as e:
            self.log.error('ERROR: ', e)
            self.log.error(traceback.format_exc())
            return False


# ---------------------------------------------
# COMPONENT THREAD THAT WILL BE STARTED BY NCS.
# ---------------------------------------------
class Main(ncs.application.Application):
    '''Nano service appliction implementing the nano create callback'''
    def setup(self):
        # The application class sets up logging for us. It is accessible
        # through 'self.log' and is a ncs.log.Log instance.
        self.log.info('Main RUNNING')

        # Nano service callbacks require a registration for a service point,
        # component, and state, as specified in the corresponding data model
        # and plan outline.

        # If we registered any callback(s) above, the Application class
        # took care of creating a daemon (related to the service/action point).
        self.register_action('skylight-notification', SkylightNotificationAction)

        # When this setup method is finished, all registrations are
        # considered done and the application is 'started'.

    def teardown(self):
        # When the application is finished (which would happen if NCS went
        # down, packages were reloaded or some error occurred) this teardown
        # method will be called.

        self.log.info('Main FINISHED')

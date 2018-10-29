#!/usr/bin/env python
# coding=utf-8
#
# Copyright © 2011-2015 Splunk, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"): you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#	 http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

from __future__ import absolute_import, division, print_function, unicode_literals
import app

from splunklib.searchcommands import dispatch, GeneratingCommand, Configuration, Option, validators
import subprocess
import sys
import time
from splunklib import six
from splunklib.six.moves import range


@Configuration()
class SSHRunScriptCommand(GeneratingCommand):

	hostkeyfile = Option(require=False)
	user = Option(require=True)
	host = Option(require=True)
	script = Option(require=True)

	def generate(self):
		hostkeyfile = self.hostkeyfile
		user = self.user
		host = self.host
		script = self.script
		ssh_arguments = []
		i = 0
		ssh_arguments.append("./ssh_exec.sh")
		# ssh_arguments.append("-t")
		if hostkeyfile is not None:
			ssh_arguments.append("-i")
			ssh_arguments.append(hostkeyfile)
		ssh_arguments.append(user + "@" + host)
		ssh_arguments.append(script)

		subprocess.check_call(ssh_arguments)
		lastrun = ""
		with open("./lastrun.txt", "r") as f:
			lastrun = f.read();
		ret_str = str(ssh_arguments) + lastrun
		yield {'_serial': 1, '_time': time.time(), '_raw': ret_str}

dispatch(SSHRunScriptCommand, sys.argv, sys.stdin, sys.stdout, __name__)

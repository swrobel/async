# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'clock'

module Async
	class Scheduler
		if Thread.instance_methods.include?(:scheduler)
			def self.supported?
				true
			end
		else
			def self.supported?
				false
			end
		end
		
		def initialize(reactor)
			@reactor = reactor
			@blocking_started_at = nil
		end
		
		def set!
			if thread = Thread.current
				thread.scheduler = self
			end
		end
		
		def clear!
			if thread = Thread.current
				thread.scheduler = nil
			end
		end
		
		private def from_descriptor(fd)
			io = IO.for_fd(fd, autoclose: false)
			return Wrapper.new(io, @reactor)
		end
		
		def wait_readable(fd, timeout = nil)
			wrapper = from_descriptor(fd)
			wrapper.wait_readable(timeout)
		ensure
			wrapper.reactor = nil
		end
		
		def wait_writable(fd)
			wrapper = from_descriptor(fd)
			wrapper.wait_writable(timeout)
		ensure
			wrapper.reactor = nil
		end
		
		def wait_for_single_fd(fd, events, duration)
			wrapper = from_descriptor(fd)
			wrapper.wait_any(duration)
		ensure
			wrapper.reactor = nil
		end
		
		def wait_sleep(duration)
			@reactor.sleep(duration)
		end
		
		def enter_blocking_region
			@blocking_started_at = Clock.now
		end
		
		def exit_blocking_region
			duration = Clock.now - @blocking_started_at
			
			if duration > 0.1
				what = caller.first
				
				warn "Blocking for #{duration.round(4)}s in #{what}." if $VERBOSE
			end
		end
	end
end

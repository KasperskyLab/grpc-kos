# © 2024 AO Kaspersky Lab
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set(DISABLED_CXX_TESTS
# SO_REUSEPORT is not defined on KasperskyOS
  oracle_event_engine_posix_test
# [VFS_SERVER_OCAP] handle_set_alloc failed create user object for handle Quota exceeded
  stranded_event_test
  tls_key_export_test
  too_many_pings_test
  message_allocator_end2end_test
  hybrid_end2end_test
  unknown_frame_bad_client_test
  remove_stream_from_stalled_lists_test
  rls_end2end_test
  xds_core_end2end_test
  xds_csds_end2end_test
  xds_fault_injection_end2end_test
  xds_outlier_detection_end2end_test
  xds_rls_end2end_test
  grpc_tool_test
  alts_concurrent_connectivity_test
  client_callback_end2end_test
  client_channel_stress_test
  settings_timeout_test
  client_lb_end2end_test
  end2end_test
  grpclb_end2end_test
  xds_cluster_end2end_test
  xds_ring_hash_end2end_test
  xds_cluster_type_end2end_test
  xds_routing_end2end_test
  xds_end2end_test
  streaming_throughput_test
# Timed out (poll)
  channelz_service_test
# Currently not supported on KasperskyOS.
  initial_settings_frame_bad_client_test
  large_metadata_bad_client_test
  headers_bad_client_test
  window_overflow_bad_client_test
  server_registered_method_bad_client_test
  simple_request_bad_client_test
  head_of_line_blocking_bad_client_test
  connection_prefix_bad_client_test
  badreq_bad_client_test
  duplicate_header_bad_client_test
  tcp_client_posix_test
  grpc_cli
  http2_client
  interop_client
  interop_server
  qps_json_driver
  qps_worker
  xds_interop_client
  xds_interop_server
  lb_get_cpu_stats_test
  stack_tracer_test
  system_roots_test
  thread_stress_test
  examine_stack_test
)

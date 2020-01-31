##
# This service streams a ZIP file with all incoming/ outgoing messages and
# attachments for each request for a given info request batch
#
class InfoRequestBatchZip
  include DownloadHelper

  ZippableFile = Struct.new(:path, :body)

  attr_reader :info_request_batch

  def initialize(info_request_batch)
    @info_request_batch = info_request_batch
  end

  def files
    files = [prepare_dashboard_metrics]

    info_request_events.each_with_object(files) do |event, memo|
      if event.outgoing?
        memo << perpare_outgoing_message(event.outgoing_message)
      elsif event.response?
        memo << perpare_incoming_message(event.incoming_message)
        event.incoming_message.foi_attachments.each do |attachment|
          memo << perpare_foi_attachment(attachment)
        end
      end
    end
  end

  def name
    generate_download_filename(
      resource: 'batch',
      id: info_request_batch.id,
      title: info_request_batch.title,
      type: 'export',
      ext: 'zip'
    )
  end

  def stream(&chunks)
    block_writer = ZipTricks::BlockWrite.new(&chunks)

    ZipTricks::Streamer.open(block_writer) do |zip|
      files.each do |file|
        zip.write_deflated_file(file.path) { |writer| writer << file.body }
      end
    end
  end

  private

  def info_request_events
    InfoRequestEvent.where(info_request: info_request_batch.info_requests).
      includes(:info_request, info_request: [:public_body]).
      includes(:outgoing_message).
      includes(:incoming_message, incoming_message: [:foi_attachments])
  end

  def prepare_dashboard_metrics
    metrics = InfoRequestBatchMetrics.new(info_request_batch)
    ZippableFile.new(metrics.name, metrics.to_csv)
  end

  def perpare_outgoing_message(message)
    sent_at = message.last_sent_at.to_formatted_s(:filename)
    name = "outgoing_#{message.id}.txt"
    path = [base_path(message.info_request), sent_at, name].join('/')

    ZippableFile.new(path, message.body)
  end

  def perpare_incoming_message(message)
    sent_at = message.sent_at.to_formatted_s(:filename)
    name = "incoming_#{message.id}.txt"
    path = [base_path(message.info_request), sent_at, name].join('/')

    ZippableFile.new(path, message.get_main_body_text_unfolded)
  end

  def perpare_foi_attachment(attachment)
    message = attachment.incoming_message
    sent_at = message.sent_at.to_formatted_s(:filename)

    path = [
      base_path(message.info_request),
      sent_at,
      'attachments',
      attachment.filename
    ].join('/')

    ZippableFile.new(path, attachment.body)
  end

  def base_path(info_request)
    [info_request.public_body.name, info_request.url_title].join(' - ')
  end
end

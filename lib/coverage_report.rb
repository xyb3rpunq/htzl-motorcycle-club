# frozen_string_literal: true

# Laporan cakupan pengujian untuk kode Ruby di lib/.
#
# Memakai modul Coverage dari pustaka standar, bukan gem tambahan, supaya tidak
# ada dependensi baru hanya demi mengukur.
#
# Yang dilaporkan baris dan cabang. Cabang lebih jujur daripada baris: satu
# baris `return nil unless x` tercatat terpakai walaupun cabang gagalnya tidak
# pernah diuji sekali pun.
#
# Cakupan metode sengaja tidak dilaporkan. Modul di sini memakai
# module_function, dan Coverage mencatat salinan instance-nya, bukan singleton
# yang benar-benar dipanggil, sehingga metode yang jelas teruji tetap tercatat
# nol. Angka cabang tidak punya masalah itu.
#
#   rake coverage

require "coverage"

Coverage.start(lines: true, branches: true)

ROOT = File.expand_path("..", __dir__)
Dir[File.join(ROOT, "test", "*_test.rb")].each { |f| require f }

Minitest.after_run do
  rows = Coverage.result.filter_map do |path, data|
    next unless path.start_with?(File.join(ROOT, "lib"))
    next if path.end_with?("coverage_report.rb")

    lines = data[:lines].compact
    branches = data[:branches].values.flat_map(&:values)

    # Nomor baris cabang yang tidak pernah diambil: inilah yang bisa
    # ditindaklanjuti, bukan sekadar persentasenya.
    branch_miss = data[:branches].values.flat_map do |targets|
      targets.filter_map { |key, count| key[2] if count.zero? }
    end

    {
      file: path.sub("#{ROOT}/", "").tr("\\", "/"),
      lines: lines.size, lines_hit: lines.count(&:positive?),
      branches: branches.size, branches_hit: branches.count(&:positive?),
      line_miss: data[:lines].each_with_index.filter_map { |c, i| i + 1 if c&.zero? },
      branch_miss: branch_miss.uniq.sort
    }
  end

  rows.sort_by! { |r| r[:branches].zero? ? 1.0 : r[:branches_hit].to_f / r[:branches] }

  pct = ->(hit, all) { all.zero? ? "  - " : format("%3d%%", hit * 100 / all) }

  puts "\nCakupan kode Ruby di lib/"
  puts "-" * 82
  puts "#{"berkas".ljust(30)}#{"baris".rjust(13)}#{"cabang".rjust(13)}  belum diuji"
  puts "-" * 82

  total = Hash.new(0)
  rows.each do |r|
    %i[lines lines_hit branches branches_hit].each { |k| total[k] += r[k] }
    catatan = []
    catatan << "baris #{r[:line_miss].first(4).join(", ")}" unless r[:line_miss].empty?
    catatan << "cabang #{r[:branch_miss].first(6).join(", ")}" unless r[:branch_miss].empty?
    puts r[:file].ljust(30) +
         "#{pct.call(r[:lines_hit], r[:lines])} #{r[:lines_hit]}/#{r[:lines]}".rjust(13) +
         "#{pct.call(r[:branches_hit], r[:branches])} #{r[:branches_hit]}/#{r[:branches]}".rjust(13) +
         "  #{catatan.join("  ")}"
  end

  line_pct = total[:lines_hit] * 100 / total[:lines]
  branch_pct = total[:branches_hit] * 100 / total[:branches]

  puts "-" * 82
  puts "TOTAL".ljust(30) +
       "#{pct.call(total[:lines_hit], total[:lines])} #{total[:lines_hit]}/#{total[:lines]}".rjust(13) +
       "#{pct.call(total[:branches_hit], total[:branches])} #{total[:branches_hit]}/#{total[:branches]}".rjust(13)

  # Ambang sengaja dipasang. Laporan yang tidak pernah bisa gagal tidak menjaga
  # apa pun; angkanya dinaikkan setiap kali celah nyata ditutup.
  min_line = Integer(ENV.fetch("MIN_LINE", "100"))
  min_branch = Integer(ENV.fetch("MIN_BRANCH", "100"))

  if line_pct < min_line || branch_pct < min_branch
    warn "\nCakupan di bawah ambang: baris #{line_pct}% (min #{min_line}%), " \
         "cabang #{branch_pct}% (min #{min_branch}%)"
    exit 1
  end

  puts "\nAmbang terpenuhi: baris >= #{min_line}%, cabang >= #{min_branch}%."
end

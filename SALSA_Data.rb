require 'benchmark'

class SALSA
	
	# rootsetからbasesetを作成
	def extraction

		# rootset
		list = [11,636,4094,5795,6936]
		# basesetでの隣接行列
		matrix = Hash.new { |h,k| h[k] = {} }
		# ノードにつけられる番号
		@number = Hash.new   
		# ページごとの番号
		num = 0	

		File.open(ARGV[0]){|file| 
			file.each_line do |line|
				first_num,second_num = line.chomp!.split(",")
				list.size.times do |i|
					if list[i].to_s == first_num || list[i].to_s == second_num
						
						if(@number[first_num] == nil)
							@number[first_num] = num
							num += 1
						end
						
						if(@number[second_num] == nil)
							@number[second_num] = num
							num += 1
						end

						matrix[@number[first_num]][@number[second_num]] = 1

						break
					end
				end
			end
		}

		File.open(ARGV[0]){|file| 

			file.each_line do |line|
				first_num,second_num = line.chomp!.split(",")
				list.size.times do |i|
					if @number.keys.include?("#{first_num}") && @number.keys.include?("#{second_num}")
						if list[i].to_s != first_num && list[i].to_s != second_num
					
							matrix[@number[first_num]][@number[second_num]] = 1

							break
						end
					end
				end
			end
		
		}

		return matrix

	end

	# 初期ベクトル作成
	def make_init
		Array.new(@number.size,1) #[1,1,1,1,1]
	end

	# 隣接行列作成(正規化)
	def make_matrix(list)
		@dim = @number.size #5
		@a = []

		@dim.times do |i|
			#ランダム遷移行列を各出リンク数で割った値を格納
			@a[i] = [] # p[0],p[1],p[2],p[3]
			@dim.times do |j|
				if(list[i][j] != nil) 
					#値に対して出リンク数で割る
					#例 [0,0,1/2,1/2]
					@a[i][j] = list[i][j] * 1.0 / list[i].count * 1.0
				else
					@a[i][j] = 0	
				end
			end
		end

	end

	# 権威行列作成
	def make_ataMatrix
		@ata = Array.new(@dim){Array.new(@dim,0)}

		@dim.times do |i|
			@dim.times do |j|
				@dim.times do |k|
					@ata[i][j] += @a.transpose[i][k] * @a[k][j]
				end
				k = 0
			end
		end
	end

	# 権威スコア計算
	def calc_authority(curr)
		15.times do #試験的に15回
			prev = curr.clone
			sum = 0
			line = []

			@dim.times do |i|
				line[i] = 0
				@dim.times do |j|
					line[i] += @ata[i][j] * prev[j]
				end
				sum += line[i]
				curr[i] = line[i]

			end
			
			@dim.times do |k|
				curr[k] = (curr[k] / sum)
			end

		end
		return curr
	end

	# ハブスコア計算
	def calc_hub(matrix)
		sum = 0
		line = []
		@dim.times do |i|
			line[i] = 0
			@dim.times do |j|
				line[i] += @a[i][j] * matrix[j]
			end
			sum += line[i]
		end

		@dim.times do |k|
			line[k] = (line[k] / sum)
		end
		return(line)
	end

	def print_matrix
		puts "-----------------"
		puts "list"
		puts @number

		puts "-----------------"
		puts "matrix"
		p @a
	end

	# 下の2つは1つにまとめる
	def print_aRanking(score)
		aRank = Hash.new
		score.size.times do |i|
			aRank[@number.key(i)] = score[i]
		end
		puts "-----------------"
		puts "authority Ranking"
		p aRank.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }
	end

	def print_hRanking(score)
		hRank = Hash.new
		score.size.times do |i|
			hRank[@number.key(i)] = score[i]
		end
		puts "-----------------"
		puts "hub Ranking"
		p hRank.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }
	end
	
end

result = Benchmark.realtime do
	
	# SALSAインスタンス作成
	x = SALSA.new

	# rootsetからbaseset抽出
	extractionList = x.extraction()
	
	# 初期ベクトル定義
	init = x.make_init()

	# 隣接行列
	x.make_matrix(extractionList)
	# 権威行列
	x.make_ataMatrix()
	
	# 各スコア計算
	aScore = x.calc_authority(init)
	hScore = x.calc_hub(aScore)

	# 出力
	x.print_matrix

	puts "-----------------"
	puts "SALSA_Authority_score"
	p aScore

	x.print_aRanking(aScore)

	puts "-----------------"
	puts "SALSA_Hub_score"
	p hScore

	x.print_hRanking(hScore)	

end

puts "-----------------"
puts "処理時間 #{result}s"
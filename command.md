git commit
git pull
git push

git remote rm origin
git remote add origin "url"
git remote -v     // show remote url

git push -u origin main


git config user.name "Carl7yan"
git config user.email "yanyi20010712@gmail.com"

git config --global --list

ssh-keygen -t rsa -C "yanyi20010712@gmail.com"
ssh -T git@github.com //测试git和github关联

git clone **



// branch
git branch -a 		// list all branch
git checkout -b name1  	// construct new branch
git checkout name2	// change branch
git merge name1 	// merge name1 in name2
git merge -d name1	// delete branch name1

// tag
git tag Nanh_RTL0.9_REV13// give a tag to current branch
git tag 		// list all tags


git reset --hard head #当前版本
git reset --hard HEAD^ #回退到上一个版本
git reset --hard HEAD^^ #回退到上上一个版本
git reset --hard HEAD~3 #回退到往上3个版本
git reset --hard HEAD~10 #回退到往上10个版本

# 分支合并发布流程：
git add .			# 将所有新增、修改或删除的文件添加到暂存区
git commit -m "版本发布" # 将暂存区的文件发版
git status 			# 查看是否还有文件没有发布上去
git checkout test	# 切换到要合并的分支
git pull			# 在test 分支上拉取最新代码，避免冲突
git merge dev   	# 在test 分支上合并 dev 分支上的代码
git push			# 上传test分支代码
